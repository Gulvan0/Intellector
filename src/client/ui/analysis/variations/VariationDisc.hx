package client.ui.analysis.variations;

import haxe.ui.containers.Box;
import intellectorboard.primitives.piece.PieceColor;

/** The small disc telling which side made a move, in the colours of the piece art **/
class VariationDisc
{
    public static function create(color:PieceColor):Box
    {
        var disc:Box = new Box();
        disc.addClass(StyleClass.VARIATION_DISC);
        disc.addClass(color == White ? StyleClass.VARIATION_DISC_WHITE : StyleClass.VARIATION_DISC_BLACK);
        disc.verticalAlign = "center";
        return disc;
    }
}
