package net.models.other;

import net.models.other.CompatibilityResolution;
import lib.json.IJsonUnserializableMacro;

class CompatibilityResponse implements IJsonUnserializableMacro
{
	public var resolution:CompatibilityResolution;
	public var server_build:Int;
	public var min_client_build:Int;
}
