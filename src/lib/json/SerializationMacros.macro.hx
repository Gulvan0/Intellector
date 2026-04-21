package lib.json;

import haxe.macro.Expr.Field;
import haxe.macro.Context;

@:keep
class SerializationMacros
{
	macro public static function build():Array<Field>
	{
		var fields = Context.getBuildFields();
		var type = Context.toComplexType(Context.getLocalType());

		var serialize:Field =
			{
				name: 'serialize',
				access: [APublic],
				pos: Context.currentPos(),
				kind: FFun(
					{
						args: [],
						ret: macro :String,
						expr: macro
						{
							var writer = new json2object.JsonWriter<$type>();
							var json = writer.write(this);
							return json;
						}
					})
			}

		fields.push(serialize);

		return fields;
	}
}
