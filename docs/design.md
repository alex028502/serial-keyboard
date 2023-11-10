### Design Choices and stuff

##### Subprojects

This project has two subjects that are pretty much independent. They don't
really "know" that they are part of a bigger project. They might "suspect" it
though since the top level project is responsible for test coverage and the
format check. The top level project runs the tests for the subprojects but
measuring coverage, and then adds that to the coverage

To keep them separate, I didn't use `../` anywhere in the project - so you
need to interact with a file that is not in the directory you are in or a
subdirectory of it, the path needs to be injected from higher level.

##### Dependencies

For completeness, I have tried to explain why this project dendends on having
everything it needs installed system wide [here](./dependencies.md) but probably
better to just believe me that this is not how I normally do it.

##### 100% coverage

Like most of my personal experiments, this project has 100% code coverage. Like
everything this rule can turn your project into another example of goodhart's
law.  However, I think that the 100% coverage rule is less vulnerable to
goodhart's law than any other % coverage rule.

Additionally, because you are manipulating the coverage rules while you are
writing the code, you can find "positive" loopholes - "I'd better use two
different functions for this so that the coverage rules tells me if I am trying
both cases." - stuff like that.

##### makefiles

Even though I am not convinced that using makefiles to cache asserts is really
worthwhile - I keep trying anyhow, and learn something new every time I fail.
