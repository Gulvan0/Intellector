package net.models.other;

import jsonmodel.IJsonSerializableMacro;

@:structInit
class ClientErrorReport implements IJsonSerializableMacro
{
    public var message:String;
    public var stack:Null<String> = null;
    public var build_id:String;
    public var page_path:String;
}
