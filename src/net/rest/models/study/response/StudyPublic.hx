package net.rest.models.study.response;

import net.rest.models.study.submodels.StudyPublicity;
import net.rest.models.study.submodels.StudyVariationNodePublic;
import net.rest.models.study.submodels.StudyTagPublic;
import net.rest.models.common.UserRefWithNickname;
import lib.stdtypes.DateTime;
import lib.json.IJsonUnserializableMacro;

class StudyPublic implements IJsonUnserializableMacro
{
    public var name:String;
    public var description:String;
    public var publicity:StudyPublicity;
    public var starting_sip:String;
    public var key_sip:String;
    public var id:Int;
    @:jcustomparse(lib.json.StdParsers.parseDate) public var created_at:DateTime;
    @:jcustomparse(lib.json.StdParsers.parseDate) public var modified_at:DateTime;
    public var author:UserRefWithNickname;
    public var deleted:Bool;
    public var tags:Array<StudyTagPublic>;
    public var nodes:Array<StudyVariationNodePublic>;
}
