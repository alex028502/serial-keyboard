class SerialMock {
 public:
  int fd;
  unsigned long baud;

  void init(int fd);
  void begin(unsigned long baud);
  void print(const char* message);
  void print(int value);
  void printf(const char* format, ...);
  void write(char value);
  int available();
  int parseInt();

 private:
  char incoming_number[32];
  char incoming_string[256];
  char incoming_line[64];
  int incoming_line_cursor;
  int incoming_string_idx;     // reading
  int incoming_string_cursor;  // writing
  int incoming_number_idx;
  int _available();
  void _update();
};

extern SerialMock Serial;
