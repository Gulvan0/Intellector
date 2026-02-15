package net.rest.models.other.response;

import net.rest.models.other.submodels.CompatibilityResolution;
import lib.json.IJsonUnserializableMacro;

class CompatibilityResponse implements IJsonUnserializableMacro
{
    public var resolution:CompatibilityResolution;
    public var server_build:Int;
    public var min_client_build:Int;
}
