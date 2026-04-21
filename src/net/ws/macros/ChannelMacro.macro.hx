package net.ws.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using lib.std.extensions.StringExtension;
using Lambda;

class ChannelMacro
{
	public static function build():Array<Field>
	{
		final cls:ClassType = Context.getLocalClass().get();
		final groupName = extractGroupName(cls);

		final fields:Array<Field> = Context.getBuildFields();
		final channelParameterFields:Array<Field> = fields.filter(isFieldChannelParameter);

		return fields.concat([
			makeGroupNameField(groupName),
			makeConstructor(channelParameterFields),
			makeToJson(groupName, channelParameterFields),
			makeHash(),
		]);
	}

	private static function makeGroupNameField(groupName:String):Field
	{
		return {
			name: "GROUP_NAME",
			access: [APublic, AStatic],
			kind: FVar(macro :String, macro $v{groupName}),
			pos: Context.currentPos(),
		};
	}

	private static function makeConstructor(channelParameterFields:Array<Field>):Field
	{
		var args:Array<FunctionArg> = [];
		var assignments:Array<Expr> = [];

		for (channelParameter in channelParameterFields)
		{
			final fieldName:String = channelParameter.name;
			args.push(
				{
					name: fieldName,
					type: getFieldType(channelParameter)
				});
			assignments.push(macro
				{this.$fieldName = $i{fieldName};});
		}

		return {
			name: "new",
			access: [APublic],
			kind: FFun(
				{
					args: args,
					ret: macro :Void,
					expr: macro $b{assignments}
				}),
			pos: Context.currentPos(),
		};
	}

	private static function makeToJson(channelGroupName:String, channelParameterFields:Array<Field>):Field
	{
		// 1. Each channel when casted to JSON will have a mandatory `group` field, let's create it
		var jsonFields:Array<ObjectField> = [
			{
				field: "group",
				expr: macro $v{channelGroupName} // The value is a string constant (channelGroupName's value)
			}
		];

		// 2. Now create a separate JSON field for each of the channel's parameters, if any
		for (channelParameter in channelParameterFields)
		{
			final fieldName:String = channelParameter.name;
			final key:String = fieldName.toSnakeCase();
			final isChannel:Bool = false; // typeImplementsIChannel(channelParameter);

			var value:Expr = macro this.$fieldName;
			if (isChannel)
				value = macro this.$fieldName.toJson();

			jsonFields.push({field: key, expr: value});
		}

		// 3. Construct a structure out of created fields and return a method yielding that structure
		final objExpr:Expr =
			{
				expr: EObjectDecl(jsonFields),
				pos: Context.currentPos()
			};

		return {
			name: "toJson",
			access: [APublic],
			kind: FFun(
				{
					args: [],
					ret: macro :Dynamic,
					expr: macro return $objExpr
				}),
			pos: Context.currentPos(),
		};
	}

	private static function makeHash():Field
	{
		return {
			name: "hash",
			access: [APublic],
			kind: FFun(
				{
					args: [],
					ret: macro :String,
					expr: macro return lib.std.Json.canonize(this.toJson())
				}),
			pos: Context.currentPos(),
		};
	}

	private static function extractGroupName(cls:ClassType):String
	{
		// Try getting from explicit metadata
		for (meta in cls.meta.get())
		{
			if (meta.name == ":channelGroup" || meta.name == "channelGroup")
			{
				if (meta.params != null && meta.params.length > 0)
					switch meta.params[0].expr
					{
						case EConst(CString(s)):
							return s;
						default:
					}
			}
		}

		return cls.name.toSnakeCase(); // Otherwise, just use a class name
	}

	private static function isFieldChannelParameter(field:Field):Bool
	{
		return switch field.kind
		{
			case FVar(_, _) | FProp("default", "never", _, _): field.access != null && field.access.contains(APublic) && !field.access.contains(AStatic);
			default: false;
		};
	}

	private static function getFieldType(field:Field):ComplexType
	{
		return switch field.kind
		{
			case FVar(t, _) if (t != null): t;
			case FProp(_, _, t, _) if (t != null): t;
			case _: Context.error('Field ${field.name} needs an explicit type annotation', field.pos);
		};
	}

	private static function isFieldIChannel(field:Field):Bool
	{
		final fieldType:ComplexType = getFieldType(field);

		switch fieldType
		{
			case TPath({name: name, params: []}) if (isTypeParam(name)):
				return true;
			case TPath(_):
				try
				{
					final resolvedType:Type = Context.resolveType(fieldType, Context.currentPos());
					switch resolvedType
					{
						case TInst(_.get() => c, _):
							return c.interfaces.exists(i -> i.t.get().name == "IChannel");
						default:
					}
				} catch (_)
				{
				}
			default:
		};

		return false;
	}

	private static function isTypeParam(name:String):Bool
	{
		return Context.getLocalClass().get().params.exists(p -> p.name == name);
	}
}
