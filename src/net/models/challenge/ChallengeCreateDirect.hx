package net.models.challenge;

import net.models.common.TimeControl;
import lib.json.IJsonSerializableMacro;

@:structInit
class ChallengeCreateDirect implements IJsonSerializableMacro
{
	public var fischer_time_control:Null<TimeControl> = null;
	public var callee_ref:String;
}
