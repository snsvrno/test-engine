class TestEngine {
 
    public static function getInput(callback : (i : String, ?o : Dynamic) -> Void){

        var text : String = "";

        var input : Null<String> = null;
        var object : Null<Dynamic> = null;

		try { 
            while (true) {
                var newline = Sys.stdin().readLine();

                // checking if we are at the next item.
                // using Device Control 1 u0011
                if(newline.charCodeAt(0) == 17) { 
                    input = text;
                    if (input.charAt(input.length-1) == "\n") input = input.substr(0, input.length-1);
                    text = "";
                // using Device Control 2 u0012
                } else if (newline.charCodeAt(0) == 18) {
                    // end of input
                    if (input != null) object = haxe.Json.parse(text);
                    else { 
                        input = text;
                        if (input.charAt(input.length-1) == "\n") input = input.substr(0, input.length-1);
                    }
                    break;
                    
                } else {
                    if (newline.length > 0) text += newline + "\n";
                }
            }

            callback(input, object);
        } catch (e) {
            Sys.exit(1);
        }

    }

    public static function done() {
        Sys.println(String.fromCharCode(0));
    }
}