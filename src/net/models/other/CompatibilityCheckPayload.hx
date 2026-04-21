package net.models.other;

import lib.json.IJsonSerializableMacro;

@:structInit
class CompatibilityCheckPayload implements IJsonSerializableMacro
{
	public var client_build:Int;
	public var min_server_build:Int;
}
