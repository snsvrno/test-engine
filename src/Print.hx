import termcolors.Termcolors.*;

using StringTools;
using termcolors.TermcolorsTools;

function error(text : String) {
	Sys.println('${red("error")}: $text');
	Sys.exit(1);
}

function warning(text : String) {
	Sys.println('${yellow("warning")}: $text');
}

function info(text : String) {
	if (!Main.options.verbose) return;
	Sys.println('${blue("info")}: $text');
}

function line(status : String, group : String, test : Test) {
	var statustext = switch(status.toLowerCase()) {
		case "failed": red(status);
		case "passed": green(status);
		case "warning": yellow(status);
		case other: other;
	}

	var namesplit = test.name.split("/");
	var processedname = [ for (i in 0 ... namesplit.length) if (i == namesplit.length - 1) yellow(namesplit[i]) else cyan(namesplit[i]) ].join("/");
	Sys.println('$statustext: ${blue(group)}/${processedname}');
}

function everything(status : String, group : String, test : Test, ?err : String) {
	line(status, group, test);

	var indent : Int = 4;
	var nl = if (Main.options.showSymbols) cyan("⮒") else "";


	printCompSection("expected", test.expectedOutput, indent, nl);
	Sys.println("");
	printCompSection("  actual", test.output, indent, nl);

	if (err != null && err.length > 0) {
		Sys.println("");
		printCompSection("   error", err, indent);
	}
}

inline private function printCompSection(title : String, content : String, indent : Int, ?nl : String) {
	var formattedTitle = yellow(title) + ":  ";
	var lines = content.split("\n");
	for (i in 0 ... lines.length) {
		var line = if (nl != null) replaceSpecialCharacters(lines[i]) + nl;
		else lines[i];
		if (i == 0) Sys.println(makeSpaces(indent) + formattedTitle + lineNumber(i+1, lines.length) + " " + line);
		else Sys.println(makeSpaces(indent + formattedTitle.truelength()) + lineNumber(i+1, lines.length) + " " + line);
	}
}

inline private function lineNumber(number : Int, max : Int) : String {
	var string = '$number';
	var max = '$max';
	while(string.length < max.length) string = " " + string;
	return magenta(string);
}


inline private function makeSpaces(length : Int) : String {
	var spaces = "";
	while(spaces.length < length) spaces += " ";
	return spaces;
}

private function replaceSpecialCharacters(string : String) {
	if (Main.options.showSymbols == false) return string;
	else return string
		.replace(" ", cyan("·"))
		.replace("\t", cyan("➞"))
		.replace("\n", cyan("⮒\n"));
}
