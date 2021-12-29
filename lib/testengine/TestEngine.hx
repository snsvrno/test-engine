package testengine;

class TestEngine {

	public inline static var ALLFINISHEDCODE : Int = 0;
	public inline static var SEPARATORCODE : Int = 17;
	public inline static var DONECODE : Int = 19;

	public static final ALLFINISHED : String = String.fromCharCode(ALLFINISHEDCODE);
	public static final SEPARATOR : String = String.fromCharCode(SEPARATORCODE);
	public static final DONE : String = String.fromCharCode(DONECODE);

	public static function getInput(callback : (i : Dynamic) -> Void) {  
		var input = { };

		try {
			while(true) {
				switch(Sys.stdin().readByte()) {

					// we are getting an input file.
					case SEPARATORCODE:
						// consume the CR that got us here.
						//Sys.stdin().readByte();

						var working : String = "";

						var ext : Null<String> = null;
						var content : Null<String> = null;
						
						var byte : Int;
						while(true) {
							byte = Sys.stdin().readByte();

							if (byte == SEPARATORCODE) {
								// consumes the newline character
								//Sys.stdin().readByte();

								// trims off the final CR
								ext = working;//.substr(0, working.length - 1);
								working = "";
							}

							else if (byte == DONECODE) {
								// consumes the newline character.
								//Sys.stdin().readByte();

								// trims off the final CR
								content = working; //.substr(0, working.length - 1);
								break;
							}

							else working += String.fromCharCode(byte);
						}

						Reflect.setProperty(input, ext, content);

					// this code means that Test-Engine is done sending things and
					// is now waiting for a transmission of the output.
					case DONECODE:
						// consume the CR
						//Sys.stdin().readByte();
						callback(input);
						Sys.exit(0);

					case other:
						var inputtext = "";
						for (ket in Reflect.fields(input)) {
							var value = Reflect.getProperty(input, ket);
							inputtext += ket + "\n";
							inputtext += "------" + "\n";
							inputtext += value + "\n";
							inputtext += "------" + "\n";
						}
						throw 'errpr got "$other" this is what we have sofar:\n$inputtext';
				}
			}
		} catch (e) {
		
			Sys.println(e.message + "\n\n" + e.details());

			Sys.exit(1);
		}
	}

	public static function done() {
		Sys.println(ALLFINISHED);
	}
}
