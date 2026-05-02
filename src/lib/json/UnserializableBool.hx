package lib.json;

import haxe.Json;

class UnserializableBool
{
    public final value:Bool;

	public function new(input:UnserializerInput)
	{
		switch input
        {
			case Str(json):
                value = cast(Json.parse(json), Bool);
			case Ast(json):
                switch json.value
                {
                    case JBool(b):
                        value = b;
                    default:
                        throw 'Type mismatch: expected bool, got ${json.value.getName()}';
                }
            case RawJson(json):
                value = cast(json, Bool);
		}
	}
}
