# How not to write a kernel module

I started this project because I wanted to write a kernel module. I wanted to do
that so I could understand a bit about drivers, and use that understanding to
fix bugs in real drivers. Some people who honestly wants to help you
succeed will tell you that you should not attempt to write your own driver
until you have helped fix an existing one, but I find it a lot easier to
understand other people's code when I have tried and failed at my own project.
The more bad makefiles I write for example, the more I learn from reading other
people's.

I wanted to create a keyboard (see the [parent project](../)) that only
spoke ASCII over a serial connection using an Arduino Nano, and write a driver
for it.

### Plan A

I thought I would write a kernel module that identified FTDI devices with
certain serial numbers or some other indicators - I would be able to configure
them like this in a a file in `/etc/modprobe.d`

```
options serial_keyboard serial_numbers="12345,67890"
```

Then I would use `MODULE_DEVICE_TABLE` to run my driver whenever an FTDI got
connected and then check against the configured serial numbers whether to
continue initializing.

My driver would then create a keyboard however other keyboard drivers create
a keyboard and get ready to send presses wherever key presses get sent.

Then I would connect to the `/dev/ttyUSB*` created by the real FTDI driver
_from_ my kernel module (still don't know if that is possible) and listen for
plain text numbers which tell you which key has been pressed, and send those
keys to the wherever keyboard drivers send keys to.

I learned pretty quickly that none of this is easy if it is possible. I created
the driver that could identify my keyboard, but realised that only one of my
driver and the real FTDI driver ever claimed the device!

That was kind of a deal breaker before I could find out if the rest of the plan
was even possible.

I considered using udev to activate my kernel module, since it only has to
interact with `/dev/ttyUSB*` and not the hardware, so doens't really need to
claim the device, but then I thought about just doing that in the user space,
and all I would need to do in the kernel space is create the keyboard that I can
send key presses to from the user space to make my keyboard work. I could make
my kernel module create a file that receives the key press codes as text, and
make a user space driver that reads from the arduino, and sends the codes over.

While I was looking into that, I found out that linux had exactly what the
kernel module I wanted to create
[built in](https://www.kernel.org/doc/html/v6.2/input/uinput.html)!

So I was left with no excuse to write any kernel code at all!

### Plan B

For a minute I tried to figure out a different excuse to write a simple
kernel module.  But then I decided to do that next idea, and use this as an
opportunity to try Lua.  I could create a library for all the
[stuff I had to do in C](./serial_keyboard_lib.c) and then do all the general
"business logic" [in lua](./serial_keyboard.lua)

This would also still be a great opportunity to brush up on my C.

### Tests

Plan B worked out great.  It took me about a day to get my keyboard working,
but then I decided I wanted to figure out how to write tests for it, and that
took me a few more weeks.

The tests are also written in Lua. Some of them are here in this project and
some are in the parent project.  It was tough to figure out how to fake the
device files and stuff.

To make the tests work I had to make an [ioctl wrapper](main/ioctl.c) that I
could easily swap out during tests with a [fake version](test/ioctl.c) that
writes all ioctl commands to the file descriptor and then read them in the
tests to make sure they are correct.

### Installer

I made a `.deb` for this driver. It works great. It gets you to enter your
FTDI serial number when you install, and then if I change the udev rule in a
later edition, it asks if you want to delete the config.

(By you I mean me - I don't actually expect anybody to ever actually install
this from a `.deb` downloaded from some guy's github.)

### Fake Arduinos

If your fake Arduino Nano is anything like my big pile of fake Arduino Nanos,
it has a CH341 instead of an FTDI. The problem with these is that they they
don't seem to have serial numbers. So you can't automatically configure a udev
rule that will distinguis the CH341 in your keyboard, from every other CH341. To
do that you have to be clever, like always plug it into the same USB jack, and
identify it from that.

Sometimes other drivers make the mistake of claiming all CH341s that get
connected to your computer. I had
[this issue](https://askubuntu.com/questions/1403705/dev-ttyusb0-not-present-in-ubuntu-22-04)
and couldn't figure out why I was having so much trouble uploading sketches to
my fake arduino. So whatever you do, don't write a udev rule that starts the
keyboard driver based on the manufacturer and product id that you see when you
plug in your fake arduino.
