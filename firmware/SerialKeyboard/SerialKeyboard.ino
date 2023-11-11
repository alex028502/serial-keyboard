#include <EEPROM.h>

#define SERIAL_KEYBOARD_BAUD 115200

const int buttonPin = 2;
const int buttonPin2 = 5;
const int defaultCode = 99;    // sysrq by default
const int defaultCode2 = 110;  // insert by default
int code;
int code2;

void setup() {
  pinMode(buttonPin, INPUT_PULLUP);
  pinMode(buttonPin2, INPUT_PULLUP);
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(SERIAL_KEYBOARD_BAUD);
  code = EEPROM.read(0);
  code2 = EEPROM.read(1);

  if (code == 255) {
    code = defaultCode;
  }
  if (code2 == 255) {
    code2 = defaultCode2;
  }
}

void message(const char* command, int c) {
  Serial.print(command);
  Serial.print(c);
  Serial.write(10);
}

void loop() {
  static int lastState = HIGH;
  static int lastState2 = HIGH;
  int currentState = digitalRead(buttonPin);
  int currentState2 = digitalRead(buttonPin2);

  /*
    I don't know if writing to gpio every iteration is so bad. also the
    tests don't really check - the only check the state of the lamp - just like
    what a human looking at a device could check. but this seems like a
    reasonable thing to do, even if we are reading from gpio every cycle so it
    can't be that big a deal - well I have no idea if writing or reading is
    worse.
   */
  int lamp = !currentState || !currentState2;
  int lastLamp = !lastState || !lastState2;
  if (lamp != lastLamp) {
    digitalWrite(LED_BUILTIN, lamp);
  }

  if (currentState != lastState) {
    if (currentState == LOW) {
      message("D", code);
    } else {
      message("U", code);
    }
    lastState = currentState;
  }

  if (currentState2 != lastState2) {
    if (currentState2 == LOW) {
      message("D", code2);
    } else {
      message("U", code2);
    }
    lastState2 = currentState2;
  }

  if (Serial.available() > 0) {
    int newCode = Serial.parseInt();
    if (newCode != 0) {
      if (newCode > 0) {
        code = newCode;
        EEPROM.write(0, code);
      } else {  // For negative input, take the positive and assign it to code2
        code2 = -newCode;
        EEPROM.write(1, code2);
      }
    }
  }
}
