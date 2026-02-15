package net.rest.models.game.request;

import net.rest.models.common.PieceColor;
import net.rest.models.game.submodels.OutcomeKind;
import lib.json.IJsonSerializableMacro;

@:generic
class ExternalGameEndPayload implements IJsonSerializableMacro
{
    public var game_id:Int;
    public var outcome_kind:OutcomeKind;
    public var winner:Null<PieceColor> = null;
}
