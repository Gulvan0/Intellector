package net.rest.models.auth.response;

import lib.json.IJsonUnserializableMacro;

class GuestTokenResponse implements IJsonUnserializableMacro
{
	public var guest_id:Int;
	public var token:String;
}
