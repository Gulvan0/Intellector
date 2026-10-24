package net.models.changelog;

import jsonmodel.IJsonUnserializableMacro;

class LocalizedParagraphsRecord implements IJsonUnserializableMacro
{
    public var en:Array<String>;
    @:default(null) public var ru:Null<Array<String>>;
}
