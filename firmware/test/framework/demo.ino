/*
this sketch is just to parseInt
the real sketch will do something a bit more complicated with it - so testing
the real sketch relies on knowing the mock framework behaves as it should
any resemblance between this test sketch that we use to test the framework
and the sketch that we are actually using the framework to test is purely
coincidental
*/

const int buttonPin = 2;
const int defaultCode = 53;
int code;

void setup() {
  pinMode(buttonPin, INPUT_PULLUP);
  Serial.begin(11111);
  code = defaultCode;
}

void message(int code) {
  Serial.print(code);
  Serial.write(10);
}

void loop() {
  static int lastState = HIGH;
  int currentState = digitalRead(buttonPin);

  if (currentState != lastState) {
    if (currentState == LOW) {
      message(code);
    }
  }
  lastState = currentState;

  if (Serial.available() > 0) {
    int newCode = Serial.parseInt();
    code = newCode;
  }
}
