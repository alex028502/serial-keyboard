/*
this sketch is just to parseInt
the real sketch will do something a bit more complicated with it - so testing
the real sketch relies on knowing the mock framework behaves as it should
any resemblance between this test sketch that we use to test the framework
and the sketch that we are actually using the framework to test is purely
coincidental
*/

const int buttonPin = 2;

void setup() {
  pinMode(buttonPin, INPUT_PULLUP);
  Serial.begin(9600);
}

void loop() {
  static int lastState = HIGH;
  int currentState = digitalRead(buttonPin);

  if (currentState != lastState) {
    if (currentState == LOW) {
      if (!Serial.available()) {
        Serial.print("unavailable");
        Serial.write(10);
      }
      int newCode = Serial.parseInt();
      Serial.print(newCode);
      Serial.write(10);
    }
  }
  lastState = currentState;
}
