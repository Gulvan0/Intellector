package gfx.game.board.util;

import net.shared.utils.MathUtils;

class BoardSize
{
    /** height/width **/
    public static function inverseAspectRatio(lettersEnabled:Bool):Float
    {
        /*
        Regarding the aspect ratio modification:

        Without letters, board's height is basically the height of a column consisting of the 7 hexes
        Or, equivalently, 7 * hex's height
        However, when we add letters, the board's height increases by a half of a hex's height
        Thus, it becomes (7 + 0.5)/7 = 15/14 of its normal value (while width stays the same)
        _
        Regarding the normal aspect ratio:

        It is trivial to prove that board's width equals 14 * hex's side
        And since our hexes are indeed hexagons, it is true that height = sqrt(3) * side
        Recall that when there are no letters, the board's height is seven times hex's height
        The rest is obvious (just substitute all of the above)
        */
        return lettersEnabled? MathUtils.HALF_SQRT3 * (15/14) : MathUtils.HALF_SQRT3;
    }

    public static function widthToHexSideLength(w:Float):Float 
    {
        return w / 14.15;
    }
}