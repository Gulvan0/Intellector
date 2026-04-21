package net.models.study;

import net.models.common.PieceKind;
import net.models.common.HexCoords;

class ApiPly
{
	public var departure:HexCoords;
	public var destination:HexCoords;
	public var morph_into:Null<PieceKind> = null;
}
