package net.models.challenge;

import net.models.common.FischerTimeControl;
import jsonmodel.IJsonSerializableMacro;

@:structInit
class ChallengeCreateOpen implements IJsonSerializableMacro
{
	public var rated:Bool;
	public var acceptor_color:ChallengeAcceptorColor;
	@:default(null) public var custom_starting_sip:Null<String>;
	public var fischer_time_control:Null<FischerTimeControl> = null;
	public var link_only:Bool;
}
