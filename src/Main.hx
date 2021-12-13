class Main {

    private static var options = {
        testsPath: "tests",
        rootPath: "",
    };
    
    private static var tests : Map<String, Array<Test>> = new Map();
    private static var definition : Map<String, TestDefinition> = new Map();

    public static function main() {
        processArgs();
        prepare();
        run();
    }

    private static function processArgs() {
        var args = Sys.args();
        
        while(args.length > 0) {
            var a = args.shift();

            if(a.substr(0,2) == "--") { 
                var value = args.shift();
                switch(a) {
                    case "--test-path": options.testsPath = value;

                    case unknown:
                        Sys.println('unknown switch "$unknown=$value"');
                }
            } else if (a.substr(0,1) == "-") {

            } else options.rootPath = a;
        }
    }

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

                var output : String = {
                    var objectPath = f + "." + def.output;
                    if (sys.FileSystem.exists(objectPath)) {
                        var content = sys.io.File.getContent(objectPath);
                        content;
                    } else {
                        Sys.println('expected file "$objectPath" found nothing');
                        Sys.exit(1);
                        "";
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

    private static function run() {
        var totalTests : Int = 0;
        var totalPassed : Int = 0;

        for(g => ts in tests) {
            var testCount : Int = 0;
            var passedTests : Int = 0;

            for (t in ts) {
                // check if we have a neko file.
                var nekopath = haxe.io.Path.join([options.rootPath, g + ".n"]);
                if (sys.FileSystem.exists(nekopath)) {
                    var process = new sys.io.Process("neko", [nekopath]);
                    process.stdin.writeString(t.input + "\n");

                    if (t.object != null) {
                        process.stdin.writeString("\n" + String.fromCharCode(17) + "\n");
                        process.stdin.writeString(t.object);
                    }
                    process.stdin.writeString("\n" + String.fromCharCode(18) + "\n");
                    
                    var byte;
                    var output = "";
                    while((byte = process.stdout.readByte()) != 0) {
                        output += String.fromCharCode(byte);
                    }
                    // removes the last return
                    output = output.substr(0, output.length-1);

                    testCount += 1;
                    totalTests += 1;

                    if (t.expectedOutput == output) { 
                        passedTests += 1;
                        totalPassed += 1;
                    } else { 
                        Sys.println('ERROR: ${t.name}');
                        Sys.println('     expected:  ${t.expectedOutput}');
                        Sys.println('     actual:    ${output}');
                    }

                    process.close();
                }
            }

            Sys.println('Test Group "$g": passed $passedTests of $testCount');
        }
        Sys.println('Total passed $totalPassed of $totalTests');


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
}