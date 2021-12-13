# Test-Engine
A language agnostic test engine written in Haxe. 

# IN PROGRESS

## Using Test-Engine
**Test-Engine** is designed to be language agnostic, so it can be run from any project. In order to use this your projects needs a few things.

1. a test definition file
2. a folder defining tests
3. a "runner" for each test group

### Test Definition
The root tests folder (`tests/` by default) is required to have a test definition file. This is a `json` file which defines the groups and what files to look for.

Example test definition for a handlebars engine.
```json
{
    "process": {
        "input": "hbs",
        "object": "json",
        "output": "html"
    }
}
```

- **process** is the 'group', typical groups could be _encode_ and _decode_ for a parser.
- **input** is the fix extension for the input text file. would be `toml` for a toml parse and in this example it is a `hbs` template file.
- **object** is a json object that is additionally passed to the "runner". this is optional if you need an object to process the **input** with.
- **output** is the output file is the expected out which the input will be compared against. 

All associated files must have the same name, and will be used together.

### Tests Folder
A folder which contains all the test files. Must contain a subfolder for each test group (which correspondes to a "runner"). Tests can be nested into folders recursively.

A directory listing of a single test "simple-expression".
```
tests/process/basic/simple-expression.hbs
tests/process/basic/simple-expression.json
tests/process/basic/simple-expression.html
tests/tests.json
```

### A Runner
A simple cli program will need to be created for each group. This is a basic program that will read `stdin` and then output on `stdout` the result. It should look for the following special characters:

|Character Name | Ascii | Unicode | Description |
|---|---|---|---|
| Device Control 1 | 17 | u0011 | Signals the end of the `input`, and the beginning of the `object` |
| Device Control 2 | 18 | u0012 | Signals the end of the `input` or the `object` |
| Null | 0 | u0000 | Signals the end of the stream |

If the runner successfully completes then it should return `0`, if there is an error it should return `1`. All error output will be ignored.

## Using with Haxe
**Test-Engine** was made primarily with Haxe in mind, so there are some convinence integrations.

You will need to make a "runner" for your test group. Each group needs its own runner. A runner is a simple neko app that calls the `TestEngine.getInput` function.

Here is the full source for the "Process runner" from my "handlebars-hx" library.
```haxe
import handlebars.Handlebars;

class Process {
    public static function main() {
        TestEngine.getInput((input : String, ?object : Dynamic) -> {
            var hb = new Handlebars(input);
            var result = hb.make(object);
            Sys.println(result);

            TestEngine.done();
        });
    }
}
```
And the hxml to build it.
```hxml
-cp tests
-cp lib

-lib test-engine

-main Process

-neko process.n
```
This will build a `process.n` in the root of the project. In order to run the test ensure that `test-engine` is installed in the project `haxelib install test-engine` and then run it in the project root. `haxelib run test-engine`. You don't need to supply anny additional paramters unless you want to run individual tests or change the tests paths.