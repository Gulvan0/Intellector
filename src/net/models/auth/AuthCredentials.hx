package net.models.auth;

import lib.json.IJsonSerializableMacro;

@:structInit
class AuthCredentials implements IJsonSerializableMacro
{
	public var login:String;
	public var password:String;
}
