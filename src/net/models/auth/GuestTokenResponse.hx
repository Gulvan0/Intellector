package net.models.auth;

import jsonmodel.IJsonUnserializableMacro;

class GuestTokenResponse implements IJsonUnserializableMacro
{
	public var guest_id:Int;
	public var token:String;
}
