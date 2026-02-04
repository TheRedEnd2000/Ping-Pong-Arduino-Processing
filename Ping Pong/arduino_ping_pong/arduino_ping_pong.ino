#define P1 A4
#define P2 A3

void setup() {
  pinMode(P1, INPUT);
  pinMode(P2, INPUT);

  Serial.begin(115200);
}

void loop() {
  int wert1 = map(analogRead(P1), 0, 1023, 0, 100);
  int wert2 = map(analogRead(P2), 0, 1023, 0, 100);

  Serial.print(wert1);
  Serial.print(",");
  Serial.println(wert2);
}
