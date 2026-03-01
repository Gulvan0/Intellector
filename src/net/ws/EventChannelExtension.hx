package net.ws;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

class EventChannelExtension
{
    public static function getChannelGroup(channel:EventChannel):String
    {
        return switch channel {
            case EveryoneEventChannel: "everyone";
            case PublicChallengeListEventChannel: "public_challenge_list";
            case GameListEventChannel: "game_list";
            case IncomingChallengesEventChannel(_): "incoming_challenges";
            case OutgoingChallengesEventChannel(_): "outgoing_challenges";
            case GameEventChannel(_): "game.main";
            case StartedPlayerGamesEventChannel(_): "player.started_games";
            case SubscriberListEventChannel(_): "subscriber_list";
        }
    }

    public static macro function getNonNestedStructureBase(channel:ExprOf<EventChannel>):ExprOf<{}>
    {
        var ctx:TypedExpr = Context.typeExpr(channel);
        var expressionType = ctx.t;

        var enumType:EnumType = switch expressionType {
            case TEnum(et, _): et.get();
            default: Context.error("Expected enum value", channel.pos);
        }

		var expr = "switch ch {";
        for (constr in enumType.constructs)
        {
			expr += 'case ${constr.name}';
			switch constr.type
			{
				case TFun(args, _):
					if (!Lambda.empty(args))
						expr += "(" + [for (arg in args) arg.name].join(", ") + ")";

                    var pairs:Array<String> = [];
					for (arg in args)
                        if (!arg.t.match(TFun(_, _) | TEnum(_, _)))
                            pairs.push('${arg.name}: ${arg.name}');

					expr += ': {${pairs.join(", ")}};';
				case TEnum(_, _):
					expr += ": {};";
				default:
					throw 'Incorrect constructor ${constr.type}';
			}
        }
        expr += "}";
		var parsedExpr = Context.parse(expr, Context.currentPos());

        return macro {
			var ch = $channel;
			var struct = $parsedExpr;
            Reflect.setField(struct, "channel_group", ch.getChannelGroup());
            struct;
		}
    }

    public static macro function serialize(channel:ExprOf<EventChannel>):ExprOf<String>
    {
        var ctx:TypedExpr = Context.typeExpr(channel);
        var expressionType = ctx.t;

        var enumType:EnumType = switch expressionType {
            case TEnum(et, _): et.get();
            default: Context.error("Expected enum value", channel.pos);
        }

		var expr = "switch ch {";
        for (constr in enumType.constructs)
        {
			switch constr.type
			{
				case TFun(args, _):
                    if (!Lambda.exists(args, arg -> arg.t.match(TFun(_, _) | TEnum(_, _))))
                        continue;

					expr += '\ncase ${constr.name}(' + [for (arg in args) arg.name].join(", ") + "):";
					for (arg in args)
                        if (arg.t.match(TFun(_, _) | TEnum(_, _)))
                            expr += '\nReflect.setField(serializedObject, "${arg.name}", ${arg.name}.getNonNestedStructureBase());';
                default:
			}
        }
        expr += "\ndefault:\n}";

		var parsedExpr = Context.parse(expr, Context.currentPos());

        return macro {
			var ch = $channel;
            var serializedObject = ch.getNonNestedStructureBase();
            ${parsedExpr}
			haxe.Json.stringify(serializedObject);
		}
    }
}
