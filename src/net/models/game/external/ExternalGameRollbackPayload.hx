package net.models.game.external;

import lib.json.IJsonSerializableMacro;

class ExternalGameRollbackPayload implements IJsonSerializableMacro
{
	public var game_id:Int;
	public var new_ply_cnt:Int;
}
