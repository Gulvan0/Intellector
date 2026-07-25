package net.models.game;

import net.models.common.PieceColor;
import jsonmodel.IJsonSerializableMacro;

@:structInit
class GameAddTimePayload implements IJsonSerializableMacro
{
	public var game_id:Int;
	public var receiver:Null<PieceColor> = null;
}
