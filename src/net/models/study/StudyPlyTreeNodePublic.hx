package net.models.study;

import net.models.common.PieceKind;

class StudyPlyTreeNodePublic
{
	public var path:String;
	public var ply_from_i:Int;
	public var ply_from_j:Int;
	public var ply_to_i:Int;
	public var ply_to_j:Int;
	@:default(null) public var ply_morph_into:Null<PieceKind>;
}
