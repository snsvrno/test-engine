import termcolors.Termcolors.*;
import Print.warning;

using MapTools;

typedef Test = {
	name: String,
	input: Map<String, String>,
	?expectedOutput: String,
	?output: String,
}

function load(suite: Map<String, TestGroupDefinition>) : Map<String, Array<Test>> {
	var loadedTests : Map<String, Array<Test>> = new Map();

	for (group => tests in suite) {
		var groupTests = new Array<Test>();

		for (file in getFiles(tests.path)) {
			var name = file.substr(tests.path.length+1);

			var input = new Map<String, String>();
			for (ti in tests.input) {
				var inputpath = file + "." + ti;
				if (sys.FileSystem.exists(inputpath)) {
					var content = sys.io.File.getContent(inputpath);
					input.set(ti, content);
				}
			}
			
			var output : Null<String> = null;
			var outputpath = file + "." + tests.output;
			if (sys.FileSystem.exists(outputpath)) output = sys.io.File.getContent(outputpath);

			if (input.isEmpty()) warning('did not find any input files for "${blue(name)}"');
			else {
				groupTests.push({
					name: name,
					input: input,
					expectedOutput: output,
				});
			}
		}
		loadedTests.set(group, groupTests);
	}

	return loadedTests;
}

private function getFiles(path : String) : Array<String> {
	var files : Array<String> = [ ];

	for (f in sys.FileSystem.readDirectory(path)) {
		var fullPath = haxe.io.Path.join([path, f]);
		
		if (sys.FileSystem.isDirectory(fullPath)) {
			var subfiles = getFiles(fullPath);
			while(subfiles.length > 0) files.push(subfiles.shift());
		} else {
			var withoutExtension = haxe.io.Path.withoutExtension(fullPath);
			if (!files.contains(withoutExtension)) files.push(withoutExtension);
		}
	}

	return files;
}
