package net.models.study;

import net.models.study.StudyPublicity;
import jsonmodel.IJsonSerializableMacro;

@:structInit
class StudyCreate implements IJsonSerializableMacro
{
	public var name:String;
	public var description:String;
	public var publicity:StudyPublicity;
	public var starting_sip:String;
	public var key_sip:String;
	public var tags:Array<String>;
	public var nodes:Array<ApiPlyTreeNode>;
}
