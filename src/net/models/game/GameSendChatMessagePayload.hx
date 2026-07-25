package net.models.game;

import jsonmodel.IJsonSerializableMacro;

@:structInit
class GameSendChatMessagePayload implements IJsonSerializableMacro
{
	public var game_id:Int;
	public var text:String;
}
