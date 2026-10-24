package net.models.changelog;

import jsonmodel.IJsonUnserializableMacro;

class LocalizedTextRecord implements IJsonUnserializableMacro
{
    public var en:String;
    @:default(null) public var ru:Null<String>;
}
