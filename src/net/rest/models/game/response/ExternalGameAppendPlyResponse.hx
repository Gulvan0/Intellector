package net.rest.models.game.response;

import net.rest.models.game.submodels.SimpleOutcome;
import lib.json.IJsonUnserializableMacro;

class ExternalGameAppendPlyResponse implements IJsonUnserializableMacro
{
    @:default(null) public var outcome:Null<SimpleOutcome>;
}
