package net.models.game;

import net.models.common.TimeControlKind;
import lib.json.IJsonUnserializableMacro;

class GameFilter implements IJsonUnserializableMacro
{
	@:default(null) public var player_ref:Null<String>;
	@:default(null) public var time_control_kind:Null<TimeControlKind>;
}
