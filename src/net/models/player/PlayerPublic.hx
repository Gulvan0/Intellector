package net.models.player;

import lib.std.DateTime;
import lib.json.IJsonUnserializableMacro;

class PlayerPublic implements IJsonUnserializableMacro
{
	public var login:String;
	@:jcustomparse(lib.json.StdParsers.parseDate) public var joined_at:DateTime;
	public var nickname:String;
	@:default(null) public var main_role:Null<UserRole>;
	public var activity:UserActivity;
}
