package net.rest.models.auth.request;

import lib.json.IJsonSerializableMacro;

@:structInit
class AuthCredentials implements IJsonSerializableMacro
{
	public var login:String;
	public var password:String;
}
