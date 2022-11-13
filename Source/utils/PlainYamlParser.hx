package utils;

using StringTools;

enum YamlNode
{
    BoolVal(value:Bool);
    IntVal(value:Int);
    FloatVal(value:Float);
    StringVal(value:String);
}

class PlainYamlDict
{
    private var map:Map<String, YamlNode> = [];

    public function getNode(key:String):Null<YamlNode>
    {
        return map.get(key);
    }

    public function getBool(key:String):Null<Bool>
    {
        var node:Null<YamlNode> = map.get(key);

        return switch node 
        {
            case BoolVal(value): value;
            default: null;
        }
    }

    public function getInt(key:String):Null<Int>
    {
        var node:Null<YamlNode> = map.get(key);

        return switch node 
        {
            case IntVal(value): value;
            default: null;
        }
    }

    public function getFloat(key:String):Null<Float>
    {
        var node:Null<YamlNode> = map.get(key);

        return switch node 
        {
            case IntVal(value): value;
            case FloatVal(value): value;
            default: null;
        }
    }

    public function getString(key:String):Null<String>
    {
        var node:Null<YamlNode> = map.get(key);

        return switch node 
        {
            case StringVal(value): value;
            case IntVal(value): Std.string(value);
            case FloatVal(value): Std.string(value);
            case BoolVal(value): Std.string(value);
            default: null;
        }
    }

    public function set(key:String, rawValue:String) 
    {
        if (rawValue == "true")
            map.set(key, BoolVal(true));
        else if (rawValue == "false")
            map.set(key, BoolVal(false));
        else if (Std.parseInt(rawValue) != null)
            map.set(key, IntVal(Std.parseInt(rawValue)));
        else if (Std.parseFloat(rawValue) != null)
            map.set(key, FloatVal(Std.parseFloat(rawValue)));
        else
            map.set(key, StringVal(rawValue));
    }

    public function new() 
    {

    }
}

class PlainYamlParser 
{
    public static function parse(text:String):PlainYamlDict
    {
        var dict:PlainYamlDict = new PlainYamlDict();

        var lines:Array<String> = text.split('\n');

        for (line in lines)
        {
            var splitted:Array<String> = line.split(':');
            dict.set(splitted[0].trim(), splitted[1].trim());
        }

        return dict;
    }
}