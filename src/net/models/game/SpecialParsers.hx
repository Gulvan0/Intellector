package net.models.game;

import net.models.common.UserRefWithNickname;
import hxjsonast.Position;
import net.models.game.GameTimeUpdatePublic;
import json2object.JsonParser;
import net.models.common.HexCoords;
import lib.std.DateTime;
import net.models.game.EventKind;
import net.models.game.GameEvent;
import hxjsonast.Json;

class SpecialParsers
{
	private static var userRefWithNicknameParser:JsonParser<UserRefWithNickname> = new JsonParser<UserRefWithNickname>();
	private static var timeUpdateParser:JsonParser<GameTimeUpdatePublic> = new JsonParser<GameTimeUpdatePublic>();

	private static function toJson(value:JsonValue):Json
	{
		return new Json(value, new Position("<inner>", 0, 0));
	}

	private static function getString(eventKind:String, eventIndex:Int, fields:Map<String, JsonValue>, key:String, required:Bool = true):Null<String>
	{
		var eventRef:String = 'Event $eventIndex (`$eventKind`) in the generic game event array';
		var field:Null<JsonValue> = fields.get(key);
		switch field
		{
			case null:
				if (required)
				{
					var presentFields:String = [for (key in fields.keys()) key].join(", ");
					throw '$eventRef is missing mandatory field $key (present fields are $presentFields)';
				} else
					return null;
			case JNull:
				if (required)
					throw '$eventRef\'s field $key is set to null despite not being optional';
				else
					return null;
			case JString(s):
				return s;
			default:
				throw '$eventRef\'s field $key is not a string (actual type: ${field.getName()})';
		}
	}

	private static function getInt(eventKind:String, eventIndex:Int, fields:Map<String, JsonValue>, key:String, required:Bool = true):Null<Int>
	{
		var eventRef:String = 'Event $eventIndex (`$eventKind`) in the generic game event array';
		var field:Null<JsonValue> = fields.get(key);
		switch field
		{
			case null:
				if (required)
				{
					var presentFields:String = [for (key in fields.keys()) key].join(", ");
					throw '$eventRef is missing mandatory field $key (present fields are $presentFields)';
				} else
					return null;
			case JNull:
				if (required)
					throw '$eventRef\'s field $key is set to null despite not being optional';
				else
					return null;
			case JNumber(s):
				var parsedInt:Null<Int> = Std.parseInt(s);
				if (parsedInt == null)
					throw '$eventRef\'s field $key is not an integer (value: $s)';
				return parsedInt;
			default:
				throw '$eventRef\'s field $key is not a number (actual type: ${field.getName()})';
		}
	}

	private static function getBool(eventKind:String, eventIndex:Int, fields:Map<String, JsonValue>, key:String, required:Bool = true):Null<Bool>
	{
		var eventRef:String = 'Event $eventIndex (`$eventKind`) in the generic game event array';
		var field:Null<JsonValue> = fields.get(key);
		switch field
		{
			case null:
				if (required)
				{
					var presentFields:String = [for (key in fields.keys()) key].join(", ");
					throw '$eventRef is missing mandatory field $key (present fields are $presentFields)';
				} else
					return null;
			case JNull:
				if (required)
					throw '$eventRef\'s field $key is set to null despite not being optional';
				else
					return null;
			case JBool(b):
				return b;
			default:
				throw '$eventRef\'s field $key is not a boolean (actual type: ${field.getName()})';
		}
	}

	public static function parsePlyEvent(fields:Map<String, JsonValue>, eventIndex:Int):GameEvent
	{
		var rawTimeUpdate:Null<JsonValue> = fields.get("time_update");
		return Ply(
			DateTime.fromIso(getString("ply", eventIndex, fields, "occurred_at")),
			getInt("ply", eventIndex, fields, "event_index"),
			getInt("ply", eventIndex, fields, "ply_index"),
			new HexCoords(getInt("ply", eventIndex, fields, "from_i"), getInt("ply", eventIndex, fields, "from_j")),
			new HexCoords(getInt("ply", eventIndex, fields, "to_i"), getInt("ply", eventIndex, fields, "to_j")),
			getString("ply", eventIndex, fields, "morph_into", false),
			rawTimeUpdate != null ? timeUpdateParser.loadJson(toJson(rawTimeUpdate)) : null,
			getBool("ply", eventIndex, fields, "is_cancelled")
		);
	}

	public static function parseChatMessageEvent(fields:Map<String, JsonValue>, eventIndex:Int):GameEvent
	{
		return ChatMessage(
			DateTime.fromIso(getString("chat_message", eventIndex, fields, "occurred_at")),
			getInt("chat_message", eventIndex, fields, "event_index"),
			getString("chat_message", eventIndex, fields, "text"),
			getBool("chat_message", eventIndex, fields, "spectator"),
			userRefWithNicknameParser.loadJson(toJson(fields.get("author")))
		);
	}

	public static function parseOfferEvent(fields:Map<String, JsonValue>, eventIndex:Int):GameEvent
	{
		return Offer(
			DateTime.fromIso(getString("offer", eventIndex, fields, "occurred_at")),
			getInt("offer", eventIndex, fields, "event_index"),
			getString("offer", eventIndex, fields, "action"),
			getString("offer", eventIndex, fields, "offer_kind"),
			getString("offer", eventIndex, fields, "offer_author")
		);
	}

	public static function parseTimeAddedEvent(fields:Map<String, JsonValue>, eventIndex:Int):GameEvent
	{
		return TimeAdded(
			DateTime.fromIso(getString("time_added", eventIndex, fields, "occurred_at")),
			getInt("time_added", eventIndex, fields, "event_index"),
			getInt("time_added", eventIndex, fields, "amount_seconds"),
			getString("time_added", eventIndex, fields, "receiver"),
			timeUpdateParser.loadJson(toJson(fields.get("time_update")))
		);
	}

	public static function parseRollbackEvent(fields:Map<String, JsonValue>, eventIndex:Int):GameEvent
	{
		var rawTimeUpdate:Null<JsonValue> = fields.get("time_update");
		return Rollback(
			DateTime.fromIso(getString("rollback", eventIndex, fields, "occurred_at")),
			getInt("rollback", eventIndex, fields, "event_index"),
			getInt("rollback", eventIndex, fields, "ply_cnt_before"),
			getInt("rollback", eventIndex, fields, "ply_cnt_after"),
			getString("rollback", eventIndex, fields, "requested_by"),
			rawTimeUpdate != null ? timeUpdateParser.loadJson(toJson(rawTimeUpdate)) : null
		);
	}

	public static function parseGenericEvent(index:Int, item:Json):GameEvent
	{
		switch item.value
		{
			case JObject(fields):
				var eventKindFields:Array<JObjectField> = fields.filter(field -> field.name == "event_kind");
				if (Lambda.empty(eventKindFields))
				{
					var eventRepr:String = "{" + fields.map(field -> '${field.name}=${field.value}').join("; ") + "}";
					throw 'Missing field "event_kind" in element $index of the generic game event array: $eventRepr';
				}

				var eventKind:EventKind;
				var rawEventKindValue:JsonValue = eventKindFields[0].value.value;
				switch rawEventKindValue
				{
					case JString(s):
						eventKind = s;
					default:
						throw 'Type mismatch: element $index in the generic game event array has a non-string event_kind field (actual type: ${rawEventKindValue.getName()})';
				}

				var eventFieldMap:Map<String, JsonValue> = [
					for (field in fields)
						if (field.name != "event_kind") field.name => field.value.value
				];
				var parserFunc:Map<String, JsonValue>->Int->GameEvent = switch eventKind
				{
					case PLY: parsePlyEvent;
					case CHAT_MESSAGE: parseChatMessageEvent;
					case OFFER: parseOfferEvent;
					case TIME_ADDED: parseTimeAddedEvent;
					case ROLLBACK: parseRollbackEvent;
				};
				return parserFunc(eventFieldMap, index);
			default:
				throw 'Type mismatch: found non-object element $index in the generic game event array (actual type: ${item.value.getName()})';
		}
	}

	public static function parseGenericEventList(val:Json, name:String):Array<GameEvent>
	{
		switch (val.value)
		{
			case JArray(values):
				return Lambda.mapi(values, parseGenericEvent);
			default:
				throw 'Type mismatch for field $name: expected Array, but got (${val.value.getName()})';
		}
	}
}
