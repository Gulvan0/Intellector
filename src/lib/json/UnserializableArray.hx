package lib.json;

import haxe.Json;
import hxjsonast.Json.JsonValue;
import hxjsonast.Parser;
import lib.json.JsonUnserializable;

@:generic
class UnserializableArray<T:JsonUnserializable>
{
    public final parsed:Array<T>;

	public function new(input:UnserializerInput)
	{
		var jsonValue:JsonValue = switch input {
			case Str(json): Parser.parse(json, "").value;
			case Ast(json): json.value;
			case RawJson(json): Parser.parse(Json.stringify(json), "").value;
		}

		switch jsonValue
		{
			case JArray(values):
				parsed = values.map(value -> new T(Ast(value)));
			default:
				throw 'Type mismatch: expected array, got ${jsonValue.getName()}';
		}
	}
}
