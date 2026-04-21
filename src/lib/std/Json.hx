package lib.std;

class Json
{
    public static function canonize(input:Dynamic):String
    {
        if (input == null)
            return "null";

        switch (Type.typeof(input))
        {
            case TInt | TFloat:
                return Std.string(input);
            case TBool:
                return input ? "true" : "false";
            case TClass(String):
                return haxe.Json.stringify(input);
            case TClass(Array):
                var arr:Array<Dynamic> = input;
                return "[" + arr.map(canonize).join(",") + "]";
            case TObject:
                var fields = Reflect.fields(input);
                fields.sort(Reflect.compare);
                var pairs = fields.map(key -> haxe.Json.stringify(key) + ":" + canonize(Reflect.field(input, key)));
                return "{" + pairs.join(",") + "}";
            default:
                return haxe.Json.stringify(input);
        }
    }
}
