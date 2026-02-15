package net.rest.models.game.request;

import net.rest.models.game.submodels.TimeRemainders;
import lib.json.IJsonSerializableMacro;

@:generic
class ExternalGameAppendPlyPayload implements IJsonSerializableMacro
{
    public var game_id:Int;
    public var from_i:Int;
    public var from_j:Int;
    public var to_i:Int;
    public var to_j:Int;
    public var morph_into:Null<PieceKind> = null;
    public var original_sip:Null<String> = null;
    public var time_remainders:Null<TimeRemainders> = null;
}
