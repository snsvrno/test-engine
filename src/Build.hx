/**
 * builds the hxml file for the runners in found.
 */
function hxml(options : Options) {
	var hxmlpath = haxe.io.Path.join([ options.path.root, options.file.hxml ]);

	if (!sys.FileSystem.exists(hxmlpath)) return;
	info('found hxml file at "${yellow(hxmlpath)}"');
	Sys.print('building "${blue(options.file.hxml)}" ... ');

	try {
		var process = new sys.io.Process("haxe", [hxmlpath]);
		var errorMsg = process.stderr.readAll().toString();
		var exitCode = process.exitCode();
		process.close();

		if (exitCode == 0) Sys.println(green("sucess"));
		else {
			Sys.println(red("failure"));
			Sys.println("\n" + errorMsg);
			Sys.exit(1);
		} 
	} catch (e) {
		Sys.println(red("failure"));
		Sys.println("\n" + e.message);
		Sys.exit(1);
	}
}
