package net.models.game.archive;

import jsonmodel.IJsonSerializableMacro;

@:structInit
class ArchiveSearchPayload implements IJsonSerializableMacro
{
    /** In the request form, as JSON **/
    @:jcustomwrite(net.models.game.archive.RawJson.write) public var formula:String;
    public var sort:Array<SortLevelPayload>;
    public var offset:Int;
    public var limit:Int;
}
