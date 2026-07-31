package net.models.game.external;

import jsonmodel.IJsonSerializableMacro;
import net.models.common.FischerTimeControl;

class ExternalGameCreatePayload implements IJsonSerializableMacro
{
	public var white_player_ref:String;
	public var black_player_ref:String;
	public var custom_starting_sip:Null<String> = null;
	public var time_control:Null<FischerTimeControl> = null;
}
