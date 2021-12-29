import termcolors.Termcolors.*;
import Print.error;

typedef TestGroupDefinition = {
	path: String,
	input: Array<String>,
	output: String,
}

/**
 * loads the test definition file defined in the options.
 */
function load(options : Options) : Map<String, TestGroupDefinition> {
	var suite : Map<String, TestGroupDefinition> = new Map();

	var fullTestPath = haxe.io.Path.join([options.path.root, options.path.tests]);
	var definitionPath = haxe.io.Path.join([fullTestPath, options.file.test]);

	if (!sys.FileSystem.exists(definitionPath)) 
		error('a test definition file must be in the root tests path. looking for "${blue(definitionPath)}"');

	try {
		var content = sys.io.File.getContent(definitionPath);
		var raw : Dynamic = haxe.Json.parse(content);

		for (group in Reflect.fields(raw)) {
			var def = Reflect.getProperty(raw, group);
			
			// ensuring that it has a valid format.
			if (!Reflect.hasField(def, "input"))
				error('test definition for group "${yellow(group)}" has no ${red("input(s)")} defined: ${blue(definitionPath)}');
			if (!Reflect.hasField(def, "output"))
				error('test definition for group "${yellow(group)}" has no ${red("output")} defined: ${blue(definitionPath)}');

			var inputs : Array<String> = [];
			var inputraw = Reflect.getProperty(def, "input");
			if (Std.isOfType(inputraw, Array)) {
				while(inputraw.length > 0) inputs.push(inputraw.shift().toString());
			} else inputs.push(inputraw.toString());
			
			suite.set(group, {
				path: haxe.io.Path.join([fullTestPath, group]),
				input: inputs,
				output: Reflect.getProperty(def, "output"),
			});
		}

	} catch (e) {
		error(e.message);	
	}

	return suite;
}
