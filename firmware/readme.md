## Idea for testing Arduino sketches

The sketch here is not especially exciting. It is for the [parent project](../)

The exciting thing is that it is tested using
[fake versions](test/framework/serial.cpp)
of the standard arduino functions and interfaces that it uses.

The tests can be written in [lua](test/test.lua).

The sketch can be compiled along with the the fake arduino library into a lua
library.

What I like about this strategy is that it worked great! When I finally finished
the framework, I added a second button to my device, and just wrote the test,
updated the implementation to pass the test, and tried it out on a real device,
where it worked perfectly the first time.

This is the
[commit](https://github.com/alex028502/serial-keyboard/commit/8ae4fb0edf7837c8712f288b1674b5af85ee3013)
(both the red and the green stage; I cleaned it up in the next few commits)

Ideally the test framework would already exist, and it would be tested really
well, by other users, and by some automated system that can compare it to real
hardware, so that the rest of us can just build the fake version and write a
quick test in lua (actually I think in real life python would work better over
all even though making it in lua was really cool) and confidently test our
sketches.

One thing I don't like about this is you can basically only have one instances
of a sketch. This is because the sketches themselves have global variables and
when lua loads the C binary, I don't think it can have two instances of a
loaded library. So it might be better to do something like this, except create
a test binary that runs out of process - and interact with it using some inter
process communication.

The lua code that loads the test version of the device looks like it is loading
and instance of something - but actually, it's all global variables inside.

##### coverage and debug and stuff

It's also awesome that you can measure test converage, and use gdb and stuff,
which you can't do on an arduino nano.  Under some circumstances it might be
worth running all your tests twice - once on real hardware, and once on a mock
framework like this.  Imagine if there were only one setup with a real arduino,
but everybody could run the mock framework locally. Then CI would make sure that
sketch worked on real hardware in case the mock framework is imperfect. CI would
also want to run it on the mock framework, if only to check coverage. The tests
could be implementated in a way that allowed them to run on both real and fake
hardware - like with two implementations of some functions or injecting
dependencies or something.  That would be cool if the one of a kind setup for
real hardware were two nanos connected together - one running the sketch, and
one running Firmata... just an idea

