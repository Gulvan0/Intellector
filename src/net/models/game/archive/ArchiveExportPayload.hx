package net.models.game.archive;

import jsonmodel.IJsonSerializableMacro;

@:structInit
class ArchiveExportPayload implements IJsonSerializableMacro
{
    /** In the request form, as JSON **/
    @:jcustomwrite(net.models.game.archive.RawJson.write) public var formula:String;
    public var sort:Array<SortLevelPayload>;
    /** In the table's order **/
    public var columns:Array<String>;
    public var include_moves:Bool;
    public var locale:String;
    /** IANA **/
    public var timezone:String;
}
