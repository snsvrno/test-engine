import testengine.TestEngine;

enum Result {
	Pass;
	Fail(msg:String);
}

enum RunnerType {
	Neko;
}

class Runner {

	private final path : String;
	private final runnerType : RunnerType;

	private var process : Null<sys.io.Process> = null;

	public function new(path : String) {
		this.path = path;

		if (path.substr(path.length-2) == ".n") runnerType = Neko;
		else throw 'does not support non-neko runners now';
	}

	public function test(t : Test) : Result {
		switch(runnerType) {
			case Neko: return testNeko(t);
		}
	}

	private function testNeko(t : Test) : Result {
		process = new sys.io.Process("neko", [path]);
		for (ext => content in t.input) send(ext, content);
		t.output = receive();
		
		var exitCode = process.exitCode();
		var errorMsg = process.stderr.readAll().toString();
		process.close();
		process = null;
	
		if (exitCode == 0 && t.output == t.expectedOutput) return Pass;
		else if (exitCode == 0 && t.expectedOutput == null) return Fail('expected runner to fail');
		else if (exitCode != 0 && t.expectedOutput == null) return Pass;
		else return Fail(errorMsg);
	}

	private function send(extension : String, content : String) {
		process.stdin.writeString(TestEngine.SEPARATOR);
		process.stdin.writeString(extension);
		process.stdin.writeString(TestEngine.SEPARATOR);
		process.stdin.writeString(content);
		process.stdin.writeString(TestEngine.DONE);
	}

	private function receive() : String {
		process.stdin.writeString(TestEngine.DONE);
		var string = process.stdout.readAll().toString();
		// strips the last three characters. should be \0 \n	
		string = string.substr(0, string.length-3);
		return string;
	}
}
