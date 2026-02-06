import processing.serial.*;
import processing.sound.*;



// Dieser COM Port ist wichtig zu ändern, falls man die Serial benutzen möchte!
String port = "COM9";



// Variablen festlegen von Bildschirm, Ball, Ballspeed und Paddles
final int SCREEN_W = 1500;
final int SCREEN_H = 1000;

final int BALL_SIZE = 30;
final int PADDLE_W = 30;
final int PADDLE_H = 300;

int PADDLE_SPEED = 6;

ArrayList<MenuBall> menuBalls = new ArrayList<MenuBall>();
int lastMenuBallSpawn = 0;
int MENU_BALL_INTERVAL = 10000; // ms

// Koordinaten des Balles und der Spieler-Paddles
int ballX, ballY;
int ballDirX = -1;
int ballDirY = 1;
int ballSpeed = 5;
int p1Y, p2Y;
int pointsP1, pointsP2 = 0;

//Tastatur boolean für smoothes Bewegen der Paddles
boolean wPressed, sPressed;
boolean pPressed, oePressed;

//Variablen für die Spieleinstellungen und der Screens
int gameOverStartTime = 0;
boolean started = false;
int pointsToWin = 3;
boolean inStartScreen = true;
boolean gameOver = false;
boolean paused = false;
boolean useKeys;
boolean invertControls = false;

boolean vsBot = false;

String[] difficultyNames = {"Baby", "Easy", "Normal", "Hard", "Very Hard", "Impossible"};
int currentDifficulty = 2;
float[] botSpeeds = {3, 5, 6, 8, 14, 20}; // passende Geschwindigkeit pro Stufe
float BOT_SPEED;

//Musik Files und Lautstärke
float masterVolume = 0.4; // 0.0 = aus, 1.0 = max
SoundFile hitSound;
SoundFile scoreSound;
SoundFile startSound;
SoundFile winSound;
SoundFile menuMusic;
SoundFile ambientMusic;

//Serial Einstellungen
Serial mySerial;
int pad1Percent, pad2Percent = 50; //Paddles-Position wird in % übertragen. Default 50% (mitte)

void setup() {
  fullScreen();
  resetBall();
  p1Y = height / 2;
  p2Y = height / 2;

  //Serial verbinden falls angeschlossen
  try {
    mySerial = new Serial(this, port, 115200);
    mySerial.bufferUntil('\n');
    useKeys = false;
  } catch (Exception e) {
    mySerial = null;
    useKeys = true;
  }

  //Sounds aus dem 'data' Ordner holen. Wichtig genau in dem Ordner
  hitSound = new SoundFile(this, "hit.mp3");
  scoreSound = new SoundFile(this, "score.mp3");
  winSound = new SoundFile(this, "win.mp3");
  startSound = new SoundFile(this, "start.mp3");
  menuMusic = new SoundFile(this, "menu.mp3");
  ambientMusic = new SoundFile(this, "ambient.mp3");

  applyVolume();
}

void draw() {
  background(255);

  //Einstellungen für den Startscreen mit Musik und dem Ball-Beispiel
  if (inStartScreen) {
    // Neue Menü-Bälle spawnen
if (millis() - lastMenuBallSpawn > MENU_BALL_INTERVAL) {
  menuBalls.add(new MenuBall());
  lastMenuBallSpawn = millis();
}

// Menü-Bälle updaten & zeichnen
for (int i = 0; i < menuBalls.size(); i++) {
  MenuBall b = menuBalls.get(i);
  b.update();
  b.draw();

  for (int j = i + 1; j < menuBalls.size(); j++) {
    b.collide(menuBalls.get(j));
  }
}
    if (!menuMusic.isPlaying()) playSound(menuMusic);
    drawStartScreen();
    return;
  }
  menuMusic.stop();

  // Game Over Screen mit Auto-Go zu StartScreen nach 5 Sekunden
  if (gameOver) {
    drawGameOver();
    if (millis() - gameOverStartTime >= 5000) {
      gameOver = false;
      inStartScreen = true;
    }
    return;
  }
  
  // Pause
if (paused) {
  textAlign(CENTER, CENTER);
  textSize(64);
  fill(0);
  text("PAUSE", width / 2, height / 2);

  textSize(20);
  text("Drücke P zum Fortsetzen", width / 2, height / 2 + 50);
  text("Drücke E zum Verlassen", width / 2, height / 2 + 70);
  return;
}


  //Ambiente Musik Loopen 
  if (!ambientMusic.isPlaying() && !paused) playSound(ambientMusic);

  //Tasten paddles Speed
  if (wPressed) p1Y -= PADDLE_SPEED;
  if (sPressed) p1Y += PADDLE_SPEED;
  if (pPressed) p2Y -= PADDLE_SPEED;
  if (oePressed) p2Y += PADDLE_SPEED;

  //Einstellung für Serial oder Keys (Paddels setzen)
  if(vsBot){
    if(useKeys){
    p1Y = constrain(p1Y, PADDLE_H/2, height - PADDLE_H/2);
  } else {
    p1Y = int(map(pad1Percent, 0, 100, PADDLE_H/2, height - PADDLE_H/2));
  }
  float targetY = ballY;
  if(p2Y < targetY){
    p2Y += BOT_SPEED;
    if(p2Y > targetY) p2Y = (int) targetY;
  } else if(p2Y > targetY){
    p2Y -= BOT_SPEED;
    if(p2Y < targetY) p2Y = (int) targetY;
  }
  
  p2Y = constrain(p2Y, PADDLE_H/2, height - PADDLE_H/2);
  }else{
    if(useKeys){
    p1Y = constrain(p1Y, PADDLE_H/2, height - PADDLE_H/2);
    p2Y = constrain(p2Y, PADDLE_H/2, height - PADDLE_H/2);
  } else {
    p1Y = int(map(pad1Percent, 0, 100, PADDLE_H/2, height - PADDLE_H/2));
    p2Y = int(map(pad2Percent, 0, 100, PADDLE_H/2, height - PADDLE_H/2));
  }
  }

  //Ball bewegen
  if (started) moveBall();

  //Die Sachen zeichnen
  drawBall();
  drawPaddles();

  // Punktestand anzeigen
  textAlign(CENTER, CENTER);
  textSize(32);
  fill(0);
  text(pointsP1 + " : " + pointsP2, width / 2, 100);
}

//Zurücksetzen des Balls, mit random Richtungsstart
void resetBall() {
  ballX = width / 2;
  ballY = height / 2;
  ballSpeed = 5;
  ballDirX = random(1) > 0.5 ? 1 : -1;
  ballDirY = random(1) > 0.5 ? 1 : -1;
}

// Ball mit den Physik-Zeugs bewegen,  zudem die Punkte-Zählung mit dabei, wo auch die Gewinne erkannt werden
void moveBall() {
  ballX += ballDirX * ballSpeed;
  ballY += ballDirY * ballSpeed;

  if (ballY <= BALL_SIZE/2 || ballY >= height - BALL_SIZE/2) {
    ballDirY *= -1;
    if(!inStartScreen) playSound(hitSound);
  }

  if (inStartScreen) {
    if (ballX <= BALL_SIZE/2 || ballX > width - BALL_SIZE/2) ballDirX *= -1;
    return;
  }

  if (ballX <= PADDLE_W + BALL_SIZE/2 &&
      ballY > p1Y - PADDLE_H/2 &&
      ballY < p1Y + PADDLE_H/2) {
    ballDirX = 1;
    ballSpeed++;
    playSound(hitSound);
  }

  if (ballX >= width - PADDLE_W - BALL_SIZE/2 &&
      ballY > p2Y - PADDLE_H/2 &&
      ballY < p2Y + PADDLE_H/2) {
    ballDirX = -1;
    ballSpeed++;
    
    playSound(hitSound);
  }

  if (ballX < 0 || ballX > width) {
    if (ballX < 0) pointsP2++;
    if (ballX > width) pointsP1++;

    if (pointsP1 >= pointsToWin || pointsP2 >= pointsToWin) {
      gameOver = true;
      gameOverStartTime = millis();
      started = false;
      ambientMusic.stop();
      playSound(winSound);
    }

    resetBall();
    if(!gameOver) playSound(scoreSound);
  }
}

// Ball ertsellen mit angegeben größen
void drawBall() {
  if (inStartScreen) {
    fill(0, 0, 0, 150);
  } else {
    fill(0);
  }
  circle(ballX, ballY, BALL_SIZE);
}

// Paddles links und rechts erstellen
void drawPaddles() {
  fill(0);
  rect(0, p1Y - PADDLE_H/2, PADDLE_W, PADDLE_H);
  rect(width - PADDLE_W, p2Y - PADDLE_H/2, PADDLE_W, PADDLE_H);
}

// Keys losgelassen check
void keyReleased() {
  if (key == 'w') wPressed = false;
  if (key == 's') sPressed = false;
  if(!vsBot){
    if (keyCode == UP) pPressed = false;
    if (keyCode == DOWN) oePressed = false;
  }
}

// Tasten Input steuerung für StartScreen und Game
void keyPressed() {
  if (inStartScreen) {
    if (key == '+' || key == '=') pointsToWin++;
    if (key == '-' && pointsToWin > 1) pointsToWin--;
    if (key == 'r') if(mySerial != null) useKeys = !useKeys;
    if (key == 'b') vsBot = !vsBot;
    if (keyCode == RIGHT) currentDifficulty = min(currentDifficulty + 1, 5);
    if (keyCode == LEFT) currentDifficulty = max(currentDifficulty -1, 0);
    if (key == 'v') { masterVolume = min(masterVolume + 0.1, 1.0); applyVolume(); }
    if (key == 'c') { masterVolume = max(masterVolume - 0.1, 0.0); applyVolume(); }
    if (keyCode == ENTER) {
      inStartScreen = false;
      started = true;
      pointsP1 = 0;
      pointsP2 = 0;
      menuBalls.clear();
      resetBall();
      playSound(startSound);
    }
    BOT_SPEED = botSpeeds[currentDifficulty];
    return;
  }
  
  if (!inStartScreen && !gameOver) {
    if (key == 'p') {
      paused = !paused; // Pause umschalten
      ambientMusic.stop();
    }
    if(paused){
      if(key == 'e'){
        paused = false;
        inStartScreen = true;
        ambientMusic.stop();
      }
    }
  }

  
  if (key == 'w') wPressed = true;
  if (key == 's') sPressed = true;
  if (keyCode == UP) pPressed = true;
  if (keyCode == DOWN) oePressed = true;
}

//Start Screen mit Einstellungen und Text
void drawStartScreen() {
  textAlign(CENTER, CENTER);
  fill(0);

  // Titel
  textSize(72);
  text("PING PONG", width / 2, height / 2 - 260);

  textSize(20);
  text("erstellt von Fabian (Credit: Adrian)", width / 2, height / 2 - 215);

  // Einstellungen Titel
  textSize(36);
  text("Spiel-Einstellungen", width / 2, height / 2 - 155);

  // Layout-Positionen
  int labelX = width / 2 - 150;
  int valueX = width / 2 + 150;
  int startY = height / 2 - 105;
  int lineH = 40;

  textSize(24);

  // Steuerung
  text("Steuerung:", labelX, startY);
  text(useKeys ? "Tastatur" : "Controller / Serial", valueX, startY);

  // Punkte
  text("Punkte zum Sieg:", labelX, startY + lineH);
  text(pointsToWin, valueX, startY + lineH);

  // Bot
  text("Gegen Bot:", labelX, startY + lineH * 2);
  text(vsBot ? "Ja" : "Nein", valueX, startY + lineH * 2);

  // Schwierigkeit nur wenn Bot aktiv
  if (vsBot) {
    text("Schwierigkeit:", labelX, startY + lineH * 3);
    text(difficultyNames[currentDifficulty], valueX, startY + lineH * 3);
  }

  // Lautstärke
  int volumeOffset = vsBot ? 4 : 3;
  text("Lautstärke:", labelX, startY + lineH * volumeOffset);
  text(round(masterVolume * 100) + "%", valueX, startY + lineH * volumeOffset);

  // Steuerhinweise
  textSize(18);
  int hintY = startY + lineH * (volumeOffset + 1) + 20;
  text("Tastatur wechseln: [ R ]", width / 2, hintY);
  text("Bot Mode wechseln: [ B ]", width / 2, hintY + 25);
  if (vsBot) {
    text("Schwierigkeit des Bots ändern: [ ← ] / [ → ]", width / 2, hintY + 50);
    text("Punkte ändern: [ + ] / [ - ]", width / 2, hintY + 75);
    text("Lautstärke ändern: [ V ] / [ C ]", width / 2, hintY + 100);
  } else {
    text("Punkte ändern: [ + ] / [ - ]", width / 2, hintY + 50);
    text("Lautstärke ändern: [ V ] / [ C ]", width / 2, hintY + 75);
  }

  // Steuerung Erklärung
  textSize(28);
  text("Steuerung", width / 2, hintY + 120 + (vsBot ? 55 : 0));

  textSize(20);
  text("Spieler 1:   W / S", width / 2, hintY + 155 + (vsBot ? 55 : 0));
  if (!vsBot)
    text("Spieler 2:   ↑ / ↓", width / 2, hintY + 180);

  // Start Hinweis
  textSize(30);
  text("ENTER zum Starten", width / 2, height - 80);
}


// Serial lesen
void serialEvent(Serial mySerial) {
  if(mySerial == null) return;
  String line = mySerial.readStringUntil('\n');
  if (line == null) return;
  line = trim(line);
  String[] values = split(line, ',');
  if (values.length == 2) {
    pad1Percent = constrain(int(values[0]), 0, 100);
    pad2Percent = constrain(int(values[1]), 0, 100);
  }
}

// Game Over Screen
void drawGameOver() {
  textAlign(CENTER, CENTER);
  fill(0);
  textSize(48);
  if (pointsP1 >= pointsToWin) text("Spieler 1 gewinnt!", width / 2, height / 2 - 40);
  else text(""+(vsBot ? "Bot": "Spieler 2")+" gewinnt!", width / 2, height / 2 - 40);
}

//Musik lautstärke
void applyVolume() {
  scoreSound.amp(masterVolume);
  winSound.amp(masterVolume);
  startSound.amp(masterVolume);
  menuMusic.amp(masterVolume); 
  ambientMusic.amp(masterVolume); 
  hitSound.amp(masterVolume);
}

void playSound(SoundFile s) {
  if (s == null) return;
  applyVolume();
  if (masterVolume <= 0.0) return; 

  s.stop();
  s.amp(masterVolume);
  s.play();
}

class MenuBall {
  float x, y;
  float vx, vy;
  float r;

  MenuBall() {
  r = random(12, 22);

  int side = int(random(4)); // 0=links,1=rechts,2=oben,3=unten

  if (side == 0) { // links
    x = -r;
    y = random(0, height);
    vx = random(1, 4);
    vy = random(-2, 2);
  } 
  else if (side == 1) { // rechts
    x = width + r;
    y = random(0, height);
    vx = random(-4, -1);
    vy = random(-2, 2);
  } 
  else if (side == 2) { // oben
    x = random(0, width);
    y = -r;
    vx = random(-2, 2);
    vy = random(1, 4);
  } 
  else { // unten
    x = random(0, width);
    y = height + r;
    vx = random(-2, 2);
    vy = random(-4, -1);
  }
}


  void update() {
  x += vx;
  y += vy;

  // Links
  if (x < r) {
    x = r;
    vx = abs(vx);   // immer nach rechts
  }

  // Rechts
  if (x > width - r) {
    x = width - r;
    vx = -abs(vx);  // immer nach links
  }

  // Oben
  if (y < r) {
    y = r;
    vy = abs(vy);   // immer nach unten
  }

  // Unten
  if (y > height - r) {
    y = height - r;
    vy = -abs(vy);  // immer nach oben
  }
}

  void draw() {
    fill(0, 120);
    noStroke();
    circle(x, y, r * 2);
  }

  void collide(MenuBall other) {
    float d = dist(x, y, other.x, other.y);
    if (d < r + other.r) {
      float tmpX = vx;
      float tmpY = vy;
      vx = other.vx;
      vy = other.vy;
      other.vx = tmpX;
      other.vy = tmpY;
    }
  }
}
