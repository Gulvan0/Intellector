package net.models.game.external;

import net.models.game.SimpleOutcome;
import jsonmodel.IJsonUnserializableMacro;

class ExternalGameAppendPlyResponse implements IJsonUnserializableMacro
{
	@:default(null) public var outcome:Null<SimpleOutcome>;
}
