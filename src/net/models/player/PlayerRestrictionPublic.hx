package net.models.player;

import lib.std.DateTime;

class PlayerRestrictionPublic
{
	public var id:Int;
	@:jcustomparse(lib.json.StdParsers.parseDate) public var casted_at:DateTime;
	@:default(null) @:jcustomparse(lib.json.StdParsers.parseOptionalDate) public var expires:Null<DateTime>;
	public var kind:UserRestrictionKind;
}
