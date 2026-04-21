package net.models.game;

import net.models.common.PieceColor;
import lib.json.IJsonSerializableMacro;

@:structInit
class GameAddTimePayload implements IJsonSerializableMacro
{
	public var game_id:Int;
	public var receiver:Null<PieceColor> = null;
}
