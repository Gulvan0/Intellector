package net.models.changelog;

import jsonmodel.IJsonUnserializableMacro;

class ChangelogEntryRecord implements IJsonUnserializableMacro
{
    public var date:String;
    public var title:LocalizedTextRecord;
    @:default(null) public var description:Null<LocalizedParagraphsRecord>;
}
