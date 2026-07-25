package net.models.game.internal;

import net.models.game.SimpleOutcome;
import net.models.game.GameTimeUpdatePublic;
import jsonmodel.IJsonUnserializableMacro;

class InternalGameAppendPlyResponse implements IJsonUnserializableMacro
{
	@:default(null) public var outcome:Null<SimpleOutcome>;
	public var sip_after:String;
	@:default(null) public var time_update:Null<GameTimeUpdatePublic>;
}
