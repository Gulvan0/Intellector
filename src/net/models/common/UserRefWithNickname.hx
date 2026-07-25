package net.models.common;

import jsonmodel.IJsonUnserializableMacro;

class UserRefWithNickname implements IJsonUnserializableMacro
{
	public var user_ref:String;
	public var nickname:String;
}
