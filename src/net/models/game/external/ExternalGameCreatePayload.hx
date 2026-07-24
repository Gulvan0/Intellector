package net.models.game.external;

import lib.json.IJsonSerializableMacro;
import net.models.common.TimeControl;

class ExternalGameCreatePayload implements IJsonSerializableMacro
{
	public var white_player_ref:String;
	public var black_player_ref:String;
	public var custom_starting_sip:Null<String> = null;
	public var time_control:Null<TimeControl> = null;
}
