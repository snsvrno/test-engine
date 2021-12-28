import termcolors.Termcolors.*;

using StringTools;
using termcolors.TermcolorsTools;

class Main {

    private static var options : Options = Options.defaults();
    private static var tests : Map<String, Array<Test>> = new Map();
    private static var definition : Map<String, TestDefinition> = new Map();

    public static function main() {
        processArgs();
        Sys.setCwd(options.rootPath);
        prepare();
        buildTestNeko();
        run();
    }

    /**
     * reads the command line arguements
     */
    private static function processArgs() {
        var args = Sys.args();
        while(args.length > 0) {
            var a = args.shift();

            if(a.substr(0,2) == "--") { 
                var value = args.shift();
                switch(a) {
                    case "--test-path": 
                        options.testsPath = value;
                    case "--group":
                        options.runGroups.push(makeRegex(value));
                    case "--test":
                        options.runTests.push(makeRegex(value));
                    case unknown:
                        Sys.println('unknown switch "$unknown=$value"');
                        Sys.exit(1);
                }
            } else if (a.substr(0,1) == "-") { 
                switch(a) {
                    case "-h":
                        printHelp();
                        Sys.exit(0);
                    case "-a": 
                        options.showall = true;
                    case "-l":
                        options.listonly = true;
                    case "-s":
                        options.showsymbols = true;
                    case unknown:
                        Sys.println('unknown switch "$unknown"');
                        Sys.exit(1);
                }
            } else options.rootPath = a;
        }

    }

    /**
     * loads the tests from the file and builds out the `test` map
     */
    private static function prepare() {

        ///////////////////////////////////////////////////////////////////////////////
        // getting the test definitions
        options.testsPath = haxe.io.Path.join([options.rootPath, options.testsPath]);
        var testDefPath = haxe.io.Path.join([options.testsPath, "tests.json"]);
        if (!sys.FileSystem.exists(testDefPath)) {
            Sys.println('a test definition json file must be defined in the root tests path: "${options.testsPath}"');
            Sys.exit(1);
        }

        try {

            var content = sys.io.File.getContent(testDefPath);
            var rawDefinition : Dynamic = haxe.Json.parse(content);

            for (group in Reflect.fields(rawDefinition)) {
                var def = Reflect.getProperty(rawDefinition, group);

                var object = if (Reflect.hasField(def, "object")) {
                    Reflect.getProperty(def, "object");
                } else null;

                definition.set(group, {
                    input: Reflect.getProperty(def, "input"),
                    output: Reflect.getProperty(def, "output"),
                    object: object,
                });
            }

        } catch (e) {
            Sys.println('Error loading test definition file: $e');
            Sys.exit(1);
        }

        ///////////////////////////////////////////////////////////////////////////////
        // LOADS THE TESTS
        for (group => def in definition) {
            var folder = haxe.io.Path.join([options.testsPath, group]);
            if (!sys.FileSystem.exists(folder)) {
                Sys.println('Error: cannot find tests for group "$group", expected folder "$folder$"');
            }
            var listOfTests : Array<Test> = [];

            for (f in getFiles(folder)) {
                // the plain text name of the test, so we can output it
                var testName = f.substr(folder.length+1);

                // checks if we are providing an object, and getting that object.
                var object : Null<String> = null;
                if (def.object != null) {
                    var objectPath = f + "." + def.object;
                    if (sys.FileSystem.exists(objectPath)) {
                        object = sys.io.File.getContent(objectPath);
                    } else {
                        Sys.println('expected file "$objectPath" found nothing');
                        Sys.exit(1);
                    }
                }

                // input string
                var input : String = {
                    var objectPath = f + "." + def.input;
                    if (sys.FileSystem.exists(objectPath)) {
                        var content = sys.io.File.getContent(objectPath);
                        content;
                    } else {
                        Sys.println('expected file "$objectPath" found nothing');
                        Sys.exit(1);
                        "";
                    }
                }

                var output : Null<String> = {
                    var objectPath = f + "." + def.output;
                    if (sys.FileSystem.exists(objectPath)) {
                        var content = sys.io.File.getContent(objectPath);
                        content;
                    } else {
                        // this is a failure test, there should be no output.
                        null;
                    }
                }

                listOfTests.push({
                    name: testName,
                    object: object,
                    input: input,
                    expectedOutput: output,
                });
            }

            tests.set(group, listOfTests);
        }


    }
    
    /**
     * checks if there is a `test.hxml` file in the directory
     * and will run it to make sure tests are up-to-date
     */
    private static function buildTestNeko() {
        var hxmlpath = haxe.io.Path.join([options.rootPath, "test.hxml"]);
        if (sys.FileSystem.exists(hxmlpath)) {
            Sys.print('found "${blue("test.hxml")}", building ...');
            
            var process = new sys.io.Process("haxe", [hxmlpath]);
            var error = process.stderr.readAll().toString();
            var exitCode = process.exitCode();
            process.close();

            if (exitCode == 0) Sys.println(green("success"));
            else {
                Sys.println(red("failure!"));
                Sys.println("");
                Sys.println(error);
                Sys.exit(1);
            }
        }
    }


    private static function run() {
        var totalTests : Int = 0;
        var totalPassed : Int = 0;

        for(g => ts in tests) {
            var testCount : Int = 0;
            var passedTests : Int = 0;

            ///////////////////////////////////////////////////////////////////////
            // various ways to check if we actually want to 
            // run this test group or not.

            var skiptestgroup = false;
            if (options.runGroups.length > 0) {
                skiptestgroup = true;
                for (rg in options.runGroups) if (rg.match(g)) skiptestgroup = false;
            }
            for (ig in options.ignoreGroups) if (ig.match(g)) skiptestgroup = true;

            ///////////////////////////////////////////////////////////////////////

            // skips the group if applicalbe.
            if (skiptestgroup) continue;

            for (t in ts) {

                //////////////////////////////////////////////////////////
                // checking if we want to skip this test.
                var skiptest = false;
                if (options.runTests.length > 0) {
                    skiptest = true;
                    for (rt in options.runTests) if (rt.match(t.name)) skiptest = false;
                }
                for (it in options.ignoreTests) if (it.match(t.name)) skiptest = true;
                //////////////////////////////////////////////////

                if (skiptest) continue;

                // check if we have a neko file for the group's `runner`.
                var nekopath = haxe.io.Path.join([options.rootPath, g + ".n"]);
                if (sys.FileSystem.exists(nekopath)) {
                    var process = new sys.io.Process("neko", [nekopath]);

                    //////////////////////////////////////////////////////
                    // THE SENDING

                    // writes the 'input' for the test to the std.
                    process.stdin.writeString(t.input);
                    // printRawOutputs(t.input);
                    // checks if we have an object to write
                    if (t.object != null) {
                        // when writing an object we need to signal that we are switching
                        // to an object by using the `17` ascii code
                        process.stdin.writeString("\n" + String.fromCharCode(17) + "\n");
                        process.stdin.writeString(t.object);
                    }

                    // we are done sending things, sending the closing ascii char `18`
                    process.stdin.writeString("\n" + String.fromCharCode(18) + "\n");

                    /////////////////////////////////////////////////////
                    // THE RECEIVING / READING

                    var byte;
                    var output = "";
                    try {
                        // reading each character from the input line.
                        while((byte = process.stdout.readByte()) != 0) {
                            output += String.fromCharCode(byte);
                        }
                    } catch (e) { }

                    var exitCode = process.exitCode();
                    process.close();

                    // removes the last return
                    output = output.substr(0, output.length-1);
                    //printRawOutputs(output);

                    testCount += 1;
                    totalTests += 1;
                    var testname = blue(g) + "::" + blue(t.name);
                    if ((t.expectedOutput == null && exitCode != 0) || t.expectedOutput == output) { 
                        passedTests += 1;
                        totalPassed += 1;
                        if (options.showall || options.listonly) printLine('passed', testname);
                    } else if (t.expectedOutput == null) {
                        throw 'this should have been a failure $testname';
                    } else {
                        if (options.listonly) printLine('error', testname);
                        else printEverything('error', testname, t.expectedOutput, output);
                    }

                } else {
                    throw 'unimplemented, only can use neko for now';
                }
            }

            Sys.println('Test Group "${blue(g)}": passed ${green(passedTests)} of ${green(testCount)}');
        }

        Sys.println('Total passed ${green(totalPassed)} of ${green(totalTests)}');


    }

    private static function printHelp() {
        Sys.println("Test Engine");
    }

    private static function getFiles(path : String) : Array<String> {
        var files : Array<String> = [ ];
        for (f in sys.FileSystem.readDirectory(path)) {
            var fullPath = haxe.io.Path.join([path, f]);
            if (sys.FileSystem.isDirectory(fullPath)) {
                var foundfiles = getFiles(fullPath);
                while(foundfiles.length > 0) files.push(foundfiles.shift());
            } else {
                var sansExtension = haxe.io.Path.withoutExtension(fullPath);
                if (!files.contains(sansExtension)) files.push(sansExtension);
            }
        }
        return files;
    }

    inline static private function makeRegex(string : String) : EReg {
        // replacing some special 'plain' wildcards with regex symbols.
        string = string
                .replace('.', '\\.')
                .replace('*','.*');

        // adding a leader and tailer so that this is an "absolute match"
        // unless they user puts *
        string = '^' + string + '$';

        return new EReg(string, 'g');
    }

    inline static private function printLine(status : String, name : String) {
        var statustext = switch(status.toLowerCase()) {
            case "error": red(status);
            case "passed": green(status);
            case "warning": yellow(status);
            case other: other;
        }

        Sys.println('$statustext: $name');
    }

    inline static private function printEverything(status : String, name : String, expected : String, actual : String) {

        printLine(status, name);

        var expectedText = yellow("expected") + ":  ";
        var actualText   = yellow("actual") + ":    ";

        var indent : Int = 4;
        var nl = if (options.showsymbols) cyan("⮒") else "";

        var elines = expected.split("\n");
        for (i in 0 ... elines.length) {
            if (i == 0) Sys.println(makeSpaces(indent) + expectedText + replaceSpecialCharacters(elines[i]) + nl);
            else Sys.println(makeSpaces(indent + expectedText.truelength()) + replaceSpecialCharacters(elines[i]) + nl);
        }

        var alines = actual.split("\n");
        for (i in 0 ... alines.length) {
            if (i == 0) Sys.println(makeSpaces(indent) + actualText + replaceSpecialCharacters(alines[i]) + nl);
            else Sys.println(makeSpaces(indent + actualText.truelength()) + replaceSpecialCharacters(alines[i]) + nl);
        }
    }

    inline private static function makeSpaces(length : Int) : String {
        var spaces = "";
        while(spaces.length < length) spaces += " ";
        return spaces;
    }

    inline private static function printRawOutputs(string : String) {
        var string = string
            .replace("\n","\\n\n");

        Sys.println(string);
    }

    inline private static function replaceSpecialCharacters(string : String) : String {
        if (options.showsymbols == false) return string;
        else return string
            .replace(" ", cyan("·"))
            .replace("\t", cyan("➞"))
            .replace("\n", cyan("⮒\n"));
    }
}
