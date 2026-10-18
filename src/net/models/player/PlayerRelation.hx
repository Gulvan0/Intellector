package net.models.player;

import morestd.DateTime;
import jsonmodel.IJsonUnserializableMacro;

class PlayerRelation implements IJsonUnserializableMacro
{
	@:default(null) @:jcustomparse(jsonmodel.StdParsers.parseOptionalDate) public var you_follow_since:Null<DateTime>;
	@:default(null) @:jcustomparse(jsonmodel.StdParsers.parseOptionalDate) public var follows_you_since:Null<DateTime>;
}
