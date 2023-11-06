#include <EEPROM.h>

#define SERIAL_KEYBOARD_BAUD 115200

const int buttonPin = 2;
const int defaultCode = 53;  // x by default
int code;

void setup() {
  pinMode(buttonPin, INPUT_PULLUP);
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(SERIAL_KEYBOARD_BAUD);
  code = EEPROM.read(0);
  if (code == 255) {
    code = defaultCode;
  }
}

void message(const char* command, int code) {
  Serial.print(command);
  Serial.print(code);
  Serial.write(10);
}

void loop() {
  static int lastState = HIGH;
  int currentState = digitalRead(buttonPin);

  if (currentState != lastState) {
    if (currentState == LOW) {
      digitalWrite(LED_BUILTIN, HIGH);
      message("D", code);
    } else {
      digitalWrite(LED_BUILTIN, LOW);
      message("U", code);
    }
    lastState = currentState;
  }

  if (Serial.available() > 0) {
    int newCode = Serial.parseInt();
    if (newCode != 0) {
      code = newCode;
      EEPROM.write(0, code);
    }
  }
}
