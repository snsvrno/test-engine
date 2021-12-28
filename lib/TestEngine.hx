class TestEngine {

    /**
     * a convinence function that will process receiving the input
     * from stdin so you don't have to.
     */
    public static function getInput(callback : (i : String, ?o : Dynamic) -> Void){

        var text : String = "";

        var input : Null<String> = null;
        var object : Null<Dynamic> = null;

        try {
            while (true) {
                // reads the line until it gets the new line character.
                var newline = Sys.stdin().readLine();
                // adding the new line because `readLine` will strip it.
                newline += "\n";

                switch(newline.charCodeAt(0)) {

                    // checking if we are at the next item.
                    // using Device Control 1 u0011
                    //
                    // this means that we are have just stopped receiveing the `input` and
                    // will start receiving the `object`.
                    case 17:
                        input = text;
                        // removes the trailing new line character at the end of the input section
                        // because that is not a 'real' new line.
                        if (input.charAt(input.length-1) == "\n") input = input.substr(0, input.length-1);
                        text = "";

                    // using Device Control 2 u0012
                    // which means we are at the end of the input and are expecting to send an output.
                    case 18:
                        // if we already set the input above then we have an object.
                        if (input != null) object = haxe.Json.parse(text);
                        // otherwise we should then set the input.
                        else { 
                            input = text;
                            // dropping the last newline because it is not a "real" newline
                            if (input.charAt(input.length-1) == "\n") input = input.substr(0, input.length-1);
                        }
                        break;

                    default:
                        if (newline.length > 0) text += newline;
                }
            }

            callback(input, object);

            Sys.exit(0);
        } catch (e) {
            Sys.exit(1);
        }

    }

    /**
      * used to tell TestEngine that processing the output is done.
      */
    public static function done() {
        Sys.println(String.fromCharCode(0));
    }
}
