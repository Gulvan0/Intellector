package net.models.game;

import net.models.common.TimeControlKind;
import jsonmodel.IJsonSerializableMacro;

@:structInit
class GameSearchPayload implements IJsonSerializableMacro
{
	public var player_ref:Null<String> = null;
	public var time_control_kinds:Null<Array<TimeControlKind>> = null;
	public var rated:Null<Bool> = null;
	public var finished:Null<Bool> = null;
	public var with_counts:Bool = false;
}
