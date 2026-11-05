package net.models.game.external;

import jsonmodel.IJsonSerializableMacro;

@:structInit
class ExternalGameHeartbeatPayload implements IJsonSerializableMacro
{
    public var game_id:Int;
}
