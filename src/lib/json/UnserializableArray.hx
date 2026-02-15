package lib.json;

import hxjsonast.Json.JsonValue;
import hxjsonast.Parser;
import lib.json.JsonUnserializable;

@:generic
class UnserializableArray<T:JsonUnserializable>
{
    public final parsed:Array<T>;

	public function new(json:String)
	{
		var jsonValue:JsonValue = Parser.parse(json, "<internal>").value;
		switch jsonValue
		{
			case JArray(values):
				parsed = values.map(value -> new T(Ast(value)));
			default:
				throw 'Type mismatch: expected array, got ${jsonValue.getName()}';
		}
	}
}
