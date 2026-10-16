package testutils;

import intellectorboard.movement.rules.PlyRules;
import intellectorboard.position.Position;
import intellectorboard.primitives.ply.RawPly;

class Plies
{
    /** The `index`-th legal ply in `position` **/
    public static function legal(position:Position, index:Int = 0):RawPly
    {
        return PlyRules.possiblePlys(position)[index];
    }
}
