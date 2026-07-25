package net.models.study;

import jsonmodel.IJsonSerializableMacro;

@:structInit
class ListStudiesPayload implements IJsonSerializableMacro
{
	public var author_login:Null<String> = null;
	public var tags:Null<Array<String>> = null;
}
