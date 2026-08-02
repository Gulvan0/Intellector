package net.models.auth;

import jsonmodel.IJsonSerializableMacro;

class AuthCredentials implements IJsonSerializableMacro
{
	public var login:String;
	public var password:String;

	public function new(login:String, password:String)
	{
		this.login = login;
		this.password = password;
	}
}
