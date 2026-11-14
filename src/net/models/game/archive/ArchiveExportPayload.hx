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
    /** The `Link` column's URL, with `{game_id}` in place of the id **/
    public var game_url_template:String;
    public var locale:String;
    /** IANA **/
    public var timezone:String;
}
