package gameboard_revamped.board_subcomponents.util;

import haxe.ui.geom.Point;
import net.shared.board.HexCoords;
import haxe.ui.util.Color;

class ArrowParams 
{
    public final color:Color;
    public final from:HexCoords;
    public final to:HexCoords;

    public function getHash():String
    {
        return color.toHex() + from.i + from.j + to.i + to.j;
    }

    public function new(color:Color, from:HexCoords, to:HexCoords) 
    {
        this.color = color;
        this.from = from;
        this.to = to;
    }
}