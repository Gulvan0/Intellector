package net.models.player;

import morestd.DateTime;
import jsonmodel.IJsonUnserializableMacro;

class PlayerPublic implements IJsonUnserializableMacro
{
	public var login:String;
	@:jcustomparse(jsonmodel.StdParsers.parseDate) public var joined_at:DateTime;
	public var nickname:String;
	@:default(null) public var main_role:Null<UserRole>;
	public var activity:UserActivity;
}
