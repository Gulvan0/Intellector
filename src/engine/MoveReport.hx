package engine;

import net.shared.board.RawPly;

enum MoveReport
{
    Best(score:Float, mainline:Array<RawPly>);
    Suboptimal(score:Float, mainline:Array<RawPly>, optimalPly:RawPly, optimalScore:Float, optimalMainline:Array<RawPly>);
}