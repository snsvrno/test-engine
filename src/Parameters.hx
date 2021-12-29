import termcolors.Termcolors.*;

using StringTools;
using termcolors.TermcolorsTools;

typedef Parameter = {
	help : String,
	runfunction : (?value : String) -> Void,
	?defaultvalue : String,
}

private var defaultOptions : Options = Options.defaults();

var parameters : Map<String, Parameter> = [
	"--test-path" => {
		help: 'the folder containing all the test files, including the "${blue("test-file")}"',
		runfunction : (?value : String) -> Main.options.path.tests = value,
		defaultvalue : defaultOptions.path.tests,
	},

	"--test-file" => {
		help: 'the file that contains the definition, is in the "${blue("test-path")}"',
		runfunction: (?value : String) -> Main.options.file.test = value,
		defaultvalue: defaultOptions.file.test,
	},

	"--hxml-file" => {
		help: 'the hxml to look for to build a haxe project',
		runfunction: (?value : String) -> Main.options.file.hxml = value,
		defaultvalue: defaultOptions.file.hxml,
	},
	
	"--test" => {
		help: 'filter for running only specific tests, can use mulitple times',
		runfunction: (?value : String) -> Main.options.filter.test.push(makeRegex(value)),
	},

	"-l" => {
		help: 'only show test titles for all run tests, both passing and failing',
		runfunction: (?value: String) -> {
			Main.options.showPassing = true;
			Main.options.titlesOnly = true;
		},
	},

	"-titles-only" => {
		help: 'only show test titles, hides details',
		runfunction: (?value : String) -> Main.options.titlesOnly = true,
	},

	"-symbols" => {
		help: 'show symbols in the output',
		runfunction: (?value: String) -> Main.options.showSymbols = true,
	},

	"-v" => {
		help: 'displays more information, verbose.',
		runfunction: (?value : String) -> Main.options.verbose = true,
	},

	"-h" => {
		help: "displays this",
		runfunction : (?value : String) -> {	
			Sys.println('Test Engine (${green(Main.options.version)})');
			Sys.println('');

			Sys.println('  USAGE: ${blue("test-engine")} [${red("<parameter> <value>")} ${yellow("<switch>")} ... ]');
			Sys.println('');

			Sys.println('    Parameters:');
			{
				var params = [ for (p in parameters.keys()) if (p.substr(0,2) == "--") p ]; 
				var maxlength = 0;
				for (p in params) {
					var defaultvalue = parameters.get(p).defaultvalue;
					if (defaultvalue == null) continue;
					var length = defaultvalue.length + p.length + 3;
					if (length > maxlength) maxlength = length;
				}
				for (p in params) {
					var fullp = parameters.get(p);
					var defaultvalue : Null<String> = parameters.get(p).defaultvalue;
					if (defaultvalue == null) defaultvalue = "";
					else defaultvalue = ' [${yellow(defaultvalue)}]';

					var length = p.length + defaultvalue.truelength();
					var padding = [ for (_ in  length ... maxlength + 4) " " ].join("");	
					Sys.println('        ${blue(p)}$defaultvalue$padding${fullp.help}');
				}
			}
			Sys.println('');

			Sys.println('    Switches:');
			{
				var switches = [ for (s in parameters.keys()) if (s.charAt(0) == "-" && s.charAt(1) != "-") s ];
				var maxlength = 0;
				for (s in switches) if (s.length > maxlength) maxlength = s.length;
				for (s in switches) {
					var padding = [ for (_ in s.length ... maxlength + 4) " " ].join("");	
					Sys.println('        ${blue(s)}$padding${parameters.get(s).help}');
				}
			}

			Sys.exit(0);

		},
	},
];

inline private function makeRegex(string : String) : EReg {
	// replacing some special 'plain' wildcards with regex symbols.
	string = string
		.replace('.', '\\.')
		.replace('*','.*');

	// adding a leader and tailer so that this is an "absolute match"
	// unless they user puts *
	string = '^' + string + '$';
	return new EReg(string, 'g');
}
