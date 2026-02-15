package net.rest.models.game.request;

import lib.json.IJsonSerializableMacro;

@:structInit
class GameSendChatMessagePayload implements IJsonSerializableMacro
{
    public var game_id:Int;
    public var text:String;
}
