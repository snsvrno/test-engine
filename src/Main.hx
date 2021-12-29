import termcolors.Termcolors.*;

class Main {

	public static var options : Options = Options.defaults();
	private static var tests : Map<String, Array<Test>>;

	public static function main() {
		parseArgs();
		loadTests();
		build();
		run();
	}

	/**
	 * reads the commandline parameters / arguements and process them into the 
	 * `options` static variable.
	 */
	private static function parseArgs() {
		var args = Sys.args();
		while(args.length > 0) {
			var arg = args.shift();
			var param = Parameters.parameters.get(arg);

			// checks for key, value pair arguements,
			if (arg.substr(0, 2) == "--") {
				var value = args.shift();
				if (param == null) {
					Sys.println('unknown switch "${blue(arg)} = ${blue(value)}"');
					Sys.exit(1);
				} else
					param.runfunction(value);

				// checks for switches.
			} else if (arg.substr(0, 1) == "-") {
				if (param == null) {
					Sys.println('unknown switch "${blue(arg)}"');
					Sys.exit(1);
				} else 
					param.runfunction();

			// all non switch arguments is the current path to use.
			} else { 
				options.path.root = arg;
				Sys.setCwd(options.path.root);
			}
		}
	}

	private static function loadTests() {
		var testsuite = TestGroupDefinition.load(options);
		tests = Test.load(testsuite);
	}

	private static function build() {
		Build.hxml(options);
	}

	private static function run() {
		var stats = new Stats();

		for (group => testSet in tests) {
			stats.newGroup();	
			// gets the runner that will be used.
			var runnerPath = haxe.io.Path.join([Main.options.path.root, group + ".n"]);
			var runner = new Runner(runnerPath);

			for (t in testSet) {
				
				if (!passesFilter(options.filter.test, t.name)) continue;

				switch(runner.test(t)) {
					case Pass: 
						stats.passed();
						if (options.showPassing) Print.line("passed", group, t);

					case Fail(msg):
						stats.failed();
						if (options.titlesOnly) Print.line("failed", group, t);
						else Print.everything("failed", group, t, msg);
				}
			}

			Sys.println('Test Group "${blue(group)}": passed ${green(stats.groupPassed)} of ${green(stats.groupTotal)}');
		}
		
		Sys.println('Test passed ${green(stats.totalPassed)} of ${green(stats.total)}');
	}

	static private function passesFilter(filter : Array<EReg>, check : String) : Bool {
		if (filter.length == 0) return true;
		for (f in filter) if (f.match(check)) return true;
		return false;
	}
}
