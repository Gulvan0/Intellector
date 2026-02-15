package net.rest.models.game.request;

import lib.json.IJsonSerializableMacro;

@:generic
class ExternalGameRollbackPayload implements IJsonSerializableMacro
{
    public var game_id:Int;
    public var new_ply_cnt:Int;
}
