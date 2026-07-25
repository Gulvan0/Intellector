package net.models.other;

import jsonmodel.IJsonSerializableMacro;

@:structInit
class CompatibilityCheckPayload implements IJsonSerializableMacro
{
	public var client_build:Int;
	public var min_server_build:Int;
}
