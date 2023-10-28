class SerialMock {
 public:
  int fd;
  unsigned long baud;

  int init();
  void begin(unsigned long baud);
  void print(const char* message);
  void print(int value);
  void printf(const char* format, ...);
  void write(char value);
  int available();
  int parseInt();
};

extern SerialMock Serial;
