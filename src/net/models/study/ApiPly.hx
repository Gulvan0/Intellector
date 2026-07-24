package net.models.study;

import net.models.common.PieceKind;
import net.models.common.HexCoords;

class ApiPly
{
	public var departure:HexCoords;
	public var destination:HexCoords;
	public var morph_into:Null<PieceKind> = null;

	public function new(departure:HexCoords, destination:HexCoords, morph_into:Null<PieceKind> = null)
	{
		this.departure = departure;
		this.destination = destination;
		this.morph_into = morph_into;
	}
}
