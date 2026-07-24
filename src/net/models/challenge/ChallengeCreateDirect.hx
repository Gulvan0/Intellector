package net.models.challenge;

import net.models.common.TimeControl;
import lib.json.IJsonSerializableMacro;

@:structInit
class ChallengeCreateDirect implements IJsonSerializableMacro
{
	public var rated:Bool;
	public var acceptor_color:ChallengeAcceptorColor;
	@:default(null) public var custom_starting_sip:Null<String>;
	public var fischer_time_control:Null<TimeControl> = null;
	public var callee_ref:String;
}
