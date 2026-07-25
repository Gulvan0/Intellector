package net.models.game.external;

import net.models.common.PieceColor;
import net.models.game.OutcomeKind;
import jsonmodel.IJsonSerializableMacro;

class ExternalGameEndPayload implements IJsonSerializableMacro
{
	public var game_id:Int;
	public var outcome_kind:OutcomeKind;
	public var winner:Null<PieceColor> = null;
}
