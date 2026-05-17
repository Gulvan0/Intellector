package lib.json;

import haxe.macro.Expr;
import haxe.macro.Context;

class UnserializationMacros
{
	macro public static function build():Array<Field>
	{
		var localClass = Context.getLocalClass().get();
		if (localClass.meta.has(":processed"))
			return null;
		localClass.meta.add(":processed", [], localClass.pos);

		var fields = Context.getBuildFields();
		var type = Context.toComplexType(Context.getLocalType());

		// Collecting class variable names
		var varNames:Array<String> = [];
		for (f in fields)
		{
			// skip static fields
			if (f.access != null && f.access.indexOf(Access.AStatic) != -1)
				continue;

			switch (f.kind)
			{
				case FVar(_, _), FProp(_, _, _, _):
					varNames.push(f.name);
				case _:
			}
		}

		var constructor:Field =
			{
				name: 'new',
				access: [APublic],
				pos: Context.currentPos(),
				kind: FFun(
					{
						args: [
							{name: 'input', type: macro :lib.json.UnserializerInput},],
						ret: macro :Void,
						expr: macro
						{
							var parser = new json2object.JsonParser<$type>();
							var builtObject:$type = switch input {
								case lib.json.UnserializerInput.Str(json): parser.fromJson(json);
								case lib.json.UnserializerInput.Ast(json): parser.loadJson(json);
								case lib.json.UnserializerInput.RawJson(json): parser.fromJson(haxe.Json.stringify(json));
							}
							if (parser.errors != null && !Lambda.empty(parser.errors))
								throw new lib.json.exceptions.UnserializationException(parser.errors);
							$b{varNames.map(name -> macro this.$name = builtObject.$name)}
						}
					})
			}

		fields.push(constructor);

		return fields;
	}
}
