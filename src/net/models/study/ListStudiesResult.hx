package net.models.study;

import jsonmodel.IJsonUnserializableMacro;

class ListStudiesResult implements IJsonUnserializableMacro
{
	public var studies:Array<StudySummaryPublic>;
	public var total:Int;
}
