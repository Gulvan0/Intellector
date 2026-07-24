package net.models.player;

import lib.std.DateTime;

class PlayerRolePublic
{
	public var role:UserRole;
	@:jcustomparse(lib.json.StdParsers.parseDate) public var granted_at:DateTime;
	public var is_main:Bool;
}
