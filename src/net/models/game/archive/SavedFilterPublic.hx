package net.models.game.archive;

import jsonmodel.IJsonUnserializableMacro;
import net.models.common.UserRefWithNickname;

class SavedFilterPublic implements IJsonUnserializableMacro
{
    public var id:Int;
    @:default(null) public var key:Null<String>;
    public var name:String;
    @:default(null) public var author:Null<UserRefWithNickname>;
    /** In the stored form, as JSON **/
    @:jcustomparse(net.models.game.archive.RawJson.parse) public var formula:String;
}
