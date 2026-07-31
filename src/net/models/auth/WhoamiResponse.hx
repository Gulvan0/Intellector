package net.models.auth;

import jsonmodel.IJsonUnserializableMacro;

class WhoamiResponse implements IJsonUnserializableMacro
{
	public var user_ref:String;
	public var nickname:String;
	public var guest_id:Null<Int>;
}
