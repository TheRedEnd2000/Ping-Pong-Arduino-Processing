import processing.serial.*;

final int SCREEN_W = 1500;
final int SCREEN_H = 1000;

final int BALL_SIZE = 30;
final int PADDLE_W = 30;
final int PADDLE_H = 300;

final int PADDLE_SPEED = 6;

int ballX, ballY;
int ballDirX = -1;
int ballDirY = 1;
int ballSpeed = 5;

int p1Y, p2Y;
int pointsP1, pointsP2 = 0;
int PUX, PUY;

boolean wPressed, sPressed;
boolean pPressed, oePressed;

boolean started = false;

int pointsToWin = 3;
boolean inStartScreen = true;
boolean gameOver = false;

boolean useKeys = false;


Serial mySerial;

int pad1Percent, pad2Percent = 50;

void setup() {
  fullScreen();
  resetBall();

  p1Y = height / 2;
  p2Y = height / 2;
  
  String port = "COM9";
  mySerial = new Serial(this, port, 115200);
  mySerial.bufferUntil('\n');
}

void draw() {
  background(255);

  if (inStartScreen) {
    drawStartScreen();
    return;
  }

  if (gameOver) {
    drawGameOver();
    return;
  }

  if (wPressed) p1Y -= PADDLE_SPEED;
  if (sPressed) p1Y += PADDLE_SPEED;
  if (pPressed) p2Y -= PADDLE_SPEED;
  if (oePressed) p2Y += PADDLE_SPEED;


  if(useKeys){
    //das für tasten
    p1Y = constrain(p1Y, PADDLE_H/2, height - PADDLE_H/2);
    p2Y = constrain(p2Y, PADDLE_H/2, height - PADDLE_H/2);
  }else{
    //das für serial
  p1Y = int(map(pad1Percent, 0, 100,
              PADDLE_H/2,
              height - PADDLE_H/2));

  p2Y = int(map(pad2Percent, 0, 100,
              PADDLE_H/2,
              height - PADDLE_H/2));
  }

  if (started) moveBall();

  drawBall();
  drawPaddles();
  //drawPowerUp();

  textAlign(CENTER, CENTER);
  textSize(32);
  fill(0);
  text(pointsP1 + " : " + pointsP2, width / 2, 100);
}


void resetBall() {
  ballX = width / 2;
  ballY = height / 2;
  ballSpeed = 5;
  ballDirX = random(1) > 0.5 ? 1 : -1;
  ballDirY = random(1) > 0.5 ? 1 : -1;
}

void moveBall() {
  ballX += ballDirX * ballSpeed;
  ballY += ballDirY * ballSpeed;

  if (ballY <= BALL_SIZE/2 || ballY >= height - BALL_SIZE/2) {
    ballDirY *= -1;
  }

  if (ballX <= PADDLE_W + BALL_SIZE/2 &&
      ballY > p1Y - PADDLE_H/2 &&
      ballY < p1Y + PADDLE_H/2) {
    ballDirX = 1;
    ballSpeed++;
  }

  if (ballX >= width - PADDLE_W - BALL_SIZE/2 &&
      ballY > p2Y - PADDLE_H/2 &&
      ballY < p2Y + PADDLE_H/2) {
    ballDirX = -1;
    ballSpeed++;
  }


  if (ballX < 0 || ballX > width) {
    if (ballX < 0) pointsP2++;
    if (ballX > width) pointsP1++;

    if (pointsP1 >= pointsToWin || pointsP2 >= pointsToWin) {
      gameOver = true;
      started = false;
    }

    resetBall();
  }

}

void drawBall() {
  fill(0);
  circle(ballX, ballY, BALL_SIZE);
}

void drawPaddles() {
  fill(0);
  rect(0, p1Y - PADDLE_H/2, PADDLE_W, PADDLE_H);
  rect(width - PADDLE_W, p2Y - PADDLE_H/2, PADDLE_W, PADDLE_H);
}

void keyReleased() {
  if (key == 'w') wPressed = false;
  if (key == 's') sPressed = false;
  if (keyCode == UP) pPressed = false;
  if (keyCode == DOWN) oePressed = false;
}

void keyPressed() {

  if (inStartScreen) {
    if (key == '+' || key == '=') pointsToWin++;
    if (key == '-' && pointsToWin > 1) pointsToWin--;
    if (key == 'r') useKeys = !useKeys;

    if (keyCode == ENTER) {
      inStartScreen = false;
      started = true;
      pointsP1 = 0;
      pointsP2 = 0;
      resetBall();
    }
    return;
  }

  if (gameOver && key == ' ') {
    gameOver = false;
    inStartScreen = true;
    return;
  }

  // SPIEL
  if (key == 'w') wPressed = true;
  if (key == 's') sPressed = true;
  if (keyCode == UP) pPressed = true;
  if (keyCode == DOWN) oePressed = true;
  if (key == 'p') spawnPowerUp();
}


void drawStartScreen() {
  textAlign(CENTER, CENTER);
  fill(0);

  textSize(64);
  text("PING PONGGGGG", width / 2, height / 2 - 200);

  textSize(32);
  text("Gespielt mit: "+ (useKeys ? "Keys" : "Serial"), width / 2, height / 2 - 100);
  text("Punkte zum Gewinnen:", width / 2, height / 2 - 50);

  textSize(48);
  text(pointsToWin, width / 2, height / 2 + 10);

  textSize(24);
  text("+ / - zum Einstellen", width / 2, height / 2 + 80);
  text("r zum Wechsel des Bewegens", width / 2, height / 2 + 120);
  text("ENTER zum Starten", width / 2, height / 2 + 160);
  
  textSize(30);
  text("Steuerung", width / 2, height / 2 + 200);
  textSize(20);
  text("Spieler 1 Bewegung mit W und S", width / 2, height / 2 + 250);
  text("Spieler 2 Bewegung mit ↑ und ↓", width / 2, height / 2 + 270);
}

void serialEvent(Serial mySerial) {
  String line = mySerial.readStringUntil('\n');
  if (line == null) return;

  line = trim(line);
  String[] values = split(line, ',');

  if (values.length == 2) {
    pad1Percent = constrain(int(values[0]), 0, 100);
    pad2Percent = constrain(int(values[1]), 0, 100);
  }
}

void spawnPowerUp(){
  PUX = (int) random(width);
  PUY = (int) random(height);
  
}

void drawPowerUp(){
  fill(0);
  rect(PUX,PUY,30,30);
}

void drawGameOver() {
  textAlign(CENTER, CENTER);
  fill(0);

  textSize(48);
  if (pointsP1 >= pointsToWin) {
    text("Spieler 1 gewinnt!", width / 2, height / 2 - 40);
  } else {
    text("Spieler 2 gewinnt!", width / 2, height / 2 - 40);
  }

  textSize(24);
  text("Leertaste für neues Spiel", width / 2, height / 2 + 40);
}
