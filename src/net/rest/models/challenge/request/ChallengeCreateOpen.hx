package net.rest.models.challenge.request;

import net.rest.models.common.TimeControl;
import lib.json.IJsonSerializableMacro;

@:structInit
class ChallengeCreateOpen implements IJsonSerializableMacro
{
	public var fischer_time_control:Null<TimeControl> = null;
	public var link_only:Bool;
}
