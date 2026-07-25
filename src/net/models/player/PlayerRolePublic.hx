package net.models.player;

import morestd.DateTime;

class PlayerRolePublic
{
	public var role:UserRole;
	@:jcustomparse(jsonmodel.StdParsers.parseDate) public var granted_at:DateTime;
	public var is_main:Bool;
}
