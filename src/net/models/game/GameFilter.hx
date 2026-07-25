package net.models.game;

import net.models.common.TimeControlKind;
import jsonmodel.IJsonSerializableMacro;

class GameFilter implements IJsonSerializableMacro
{
	@:default(null) public var player_ref:Null<String>;
	@:default(null) public var time_control_kind:Null<TimeControlKind>;
}
