package net.models.player;

import morestd.DateTime;

class PlayerRestrictionPublic
{
	public var id:Int;
	@:jcustomparse(jsonmodel.StdParsers.parseDate) public var casted_at:DateTime;
	@:default(null) @:jcustomparse(jsonmodel.StdParsers.parseOptionalDate) public var expires:Null<DateTime>;
	public var kind:UserRestrictionKind;
}
