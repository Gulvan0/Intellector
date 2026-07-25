package net.models.auth;

import jsonmodel.IJsonSerializableMacro;

@:structInit
class AuthCredentials implements IJsonSerializableMacro
{
	public var login:String;
	public var password:String;
}
