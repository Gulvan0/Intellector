package net.models.study;

import net.models.study.StudyPublicity;
import lib.json.IJsonSerializableMacro;

@:structInit
class StudyUpdate implements IJsonSerializableMacro
{
	public var name:Null<String> = null;
	public var description:Null<String> = null;
	public var publicity:Null<StudyPublicity> = null;
	public var starting_sip:Null<String> = null;
	public var key_sip:Null<String> = null;
	public var tags:Null<Array<String>> = null;
	public var nodes:Null<Array<ApiPlyTreeNode>> = null;
}
