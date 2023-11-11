#include <EEPROM.h>

#define SERIAL_KEYBOARD_BAUD 115200

const int buttonPin[] = {2, 5};
const int defaultCode[] = {99, 110};  // sysrq, insert by default
int code[2];

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(SERIAL_KEYBOARD_BAUD);
  for (int i = 0; i < 2; i++) {
    pinMode(buttonPin[i], INPUT_PULLUP);
    code[i] = EEPROM.read(i);
    if (code[i] == 255) {
      code[i] = defaultCode[i];
    }
  }
}

void message(const char* command, int c) {
  Serial.print(command);
  Serial.print(c);
  Serial.write(10);
}

void loop() {
  static int lastState[] = {HIGH, HIGH};
  int currentState[2];
  for (int i = 0; i < 2; i++) {
    currentState[i] = digitalRead(buttonPin[i]);
  }

  /*
    I don't know if writing to gpio every iteration is so bad. also the
    tests don't really check - the only check the state of the lamp - just like
    what a human looking at a device could check. but this seems like a
    reasonable thing to do, even if we are reading from gpio every cycle so it
    can't be that big a deal - well I have no idea if writing or reading is
    worse.
   */
  int lamp = !currentState[0] || !currentState[1];
  int lastLamp = !lastState[0] || !lastState[1];
  if (lamp != lastLamp) {
    digitalWrite(LED_BUILTIN, lamp);
  }

  for (int i = 0; i < 2; i++) {
    if (currentState[i] != lastState[i]) {
      if (currentState[i] == LOW) {
        message("D", code[i]);
      } else {
        message("U", code[i]);
      }
      lastState[i] = currentState[i];
    }
  }

  if (Serial.available() > 0) {
    int newCode = Serial.parseInt();
    if (newCode != 0) {
      // For negative input, take the positive and assign it to code[1]
      int i = newCode < 0;  // button #1 is the secondary button
      code[i] = abs(newCode);
      EEPROM.write(i, code[i]);
    }
  }
}
