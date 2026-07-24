package net.models.game;

import net.models.common.PieceColor;
import net.models.game.OutcomeKind;

class SimpleOutcome
{
	public var kind:OutcomeKind;
	@:default(null) public var winner:Null<PieceColor>;
}
