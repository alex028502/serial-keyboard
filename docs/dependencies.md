## dependencies

Because of the subproject structure, I got a bit twisted up trying to
figure out where to put a lot of dependencies - so I decided to install all
dependencies globally. The only place where the dependencies are tracked is
in the the test job in github actions.

Usually I am the first person to tell you to never use `npm -g` or `pip`
without a `venv` unless you have a good reason, and you know what that reason
is.

But, on top of not being able to work out a nice pattern for sharing
dependencies between the two projects, and not really figuring out how local
luarocks is supposed to work, I have noticed a few things lately to make me
wonder if global dependencies are really any worse than anything else - like
the other week I tried to run the CI for [this project](../serverless-security)
and it failed because the container I was using with the python version I
tried to freeze to no longer exists, and then it failed again because the
ruby I was using was too old. Luckily it passed when I upgraded ruby, but I
started to wonder, what's the point in keeping your dependencies fixed when you
can't even keep your interterpreter fixed, and even if you could, there will
be critical security issues found. And some time ago, the gitlab CI for a
project of mine just stopped working. I can't remember why.
So the idea that if you fix all your dependencies, you will be able to just
run the CI for old versions of your project - well it's not gonna work.

Also tons of dependencies always come from `apt` and just generally from your
distro version - in this project `lcov` `socat` `gcc` - which kind of ties into
the previous point - that you can't successfully lock down your ubuntu version.

So I decided in this project I would just install everything globally, even
stuff installed with `gem` and `luarocks` and sometimes I will get a
notification that CI failed. I have set CI to build every month even if I don't
push.

I mean to be fair it's probably not about going back three months; it's about
going back three days - well there are a lot of reasons that fixing as many
dependencies as possible is the way to go.  I am not recommending the strategy
used in this project - just seeing how it works out.
