package net.models.game.archive;

import jsonmodel.IJsonSerializableMacro;

@:structInit
class SaveFilterPayload implements IJsonSerializableMacro
{
    public var name:String;
    /** In the stored form, as JSON **/
    @:jcustomwrite(net.models.game.archive.RawJson.write) public var formula:String;
    public var overwrite:Bool;
}
