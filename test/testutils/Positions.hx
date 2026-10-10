package testutils;

import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceKind;

typedef Placement =
{
    i:Int,
    j:Int,
    kind:PieceKind,
    color:PieceColor
}

class Positions
{
    public static function make(turnColor:PieceColor, placements:Array<Placement>):Position
    {
        var position:Position = Position.empty().copy(turnColor);
        for (placement in placements)
            position.setPiece(new HexCoords(placement.i, placement.j), placement.kind, placement.color);
        return position;
    }

    /** `hexes` as scalar coordinates, comparable with `Assert.same` **/
    public static function scalars(hexes:Array<HexCoords>):Array<Int>
    {
        return hexes.map(coords -> coords.toScalarCoord());
    }

    /** `hexes` as ascending scalar coordinates, for comparing regardless of order **/
    public static function sortedScalars(hexes:Array<HexCoords>):Array<Int>
    {
        var result:Array<Int> = scalars(hexes);
        result.sort(Reflect.compare);
        return result;
    }
}
