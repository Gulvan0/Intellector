package net.models.game.internal;

import net.models.common.PieceKind;
import jsonmodel.IJsonSerializableMacro;

@:structInit
class InternalGameAppendPlyPayload implements IJsonSerializableMacro
{
	public var game_id:Int;
	public var from_i:Int;
	public var from_j:Int;
	public var to_i:Int;
	public var to_j:Int;
	public var morph_into:Null<PieceKind> = null;
	public var original_sip:Null<String> = null;
}
