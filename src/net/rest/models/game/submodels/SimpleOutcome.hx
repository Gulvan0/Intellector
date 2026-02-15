package net.rest.models.game.submodels;

import net.rest.models.common.PieceColor;

class SimpleOutcome
{
	public var kind:OutcomeKind;
	@:default(null) public var winner:Null<PieceColor>;
}
