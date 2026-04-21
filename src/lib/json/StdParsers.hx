package lib.json;

import lib.std.DateTime;
import hxjsonast.Json;

class StdParsers
{
	public static function parseDate(val:Json, name:String):DateTime
	{
		switch (val.value)
		{
			case JString(s):
				return DateTime.fromIso(s);
			default:
				throw 'Type mismatch for field $name: expected Date represented as a String, but got a non-String value (${val.value.getName()})';
		}
	}

	public static function parseOptionalDate(val:Json, name:String):Null<DateTime>
	{
		switch (val.value)
		{
			case JString(s):
				return DateTime.fromIso(s);
			case JNull:
				return null;
			default:
				throw 'Type mismatch for field $name: expected Date represented as a String, but got a non-String value (${val.value.getName()})';
		}
	}
}
