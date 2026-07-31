package net.models.auth;

import jsonmodel.IJsonUnserializableMacro;
import net.models.common.UserRefWithNickname;

class TokenResponse implements IJsonUnserializableMacro
{
	public var token:String;
	public var identity:UserRefWithNickname;
}
