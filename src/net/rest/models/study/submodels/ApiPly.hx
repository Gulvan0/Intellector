package net.rest.models.study.submodels;

import net.rest.models.common.PieceKind;
import net.rest.models.common.HexCoords;

class ApiPly
{
    public var departure:HexCoords;
    public var destination:HexCoords;
    public var morph_into:Null<PieceKind> = null;
}
