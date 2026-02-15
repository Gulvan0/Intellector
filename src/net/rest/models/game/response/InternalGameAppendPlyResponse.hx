package net.rest.models.game.response;

import net.rest.models.game.submodels.SimpleOutcome;
import lib.json.IJsonUnserializableMacro;

class InternalGameAppendPlyResponse implements IJsonUnserializableMacro
{
    @:default(null) public var outcome:Null<SimpleOutcome>;
    public var sip_after:String;
    @:default(null) public var time_update:Null<GameTimeUpdatePublic>;
}
