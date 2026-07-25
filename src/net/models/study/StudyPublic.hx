package net.models.study;

import net.models.study.StudyPublicity;
import net.models.study.StudyPlyTreeNodePublic;
import net.models.study.StudyTagPublic;
import net.models.common.UserRefWithNickname;
import morestd.DateTime;
import jsonmodel.IJsonUnserializableMacro;

class StudyPublic implements IJsonUnserializableMacro
{
	public var name:String;
	public var description:String;
	public var publicity:StudyPublicity;
	public var starting_sip:String;
	public var key_sip:String;
	public var id:Int;
	@:jcustomparse(jsonmodel.StdParsers.parseDate) public var created_at:DateTime;
	@:jcustomparse(jsonmodel.StdParsers.parseDate) public var modified_at:DateTime;
	public var author:UserRefWithNickname;
	public var deleted:Bool;
	public var tags:Array<StudyTagPublic>;
	public var nodes:Array<StudyPlyTreeNodePublic>;
}
