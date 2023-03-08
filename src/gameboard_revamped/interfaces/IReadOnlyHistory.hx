package gameboard_revamped.interfaces;

import net.shared.board.RawPly;
import net.shared.board.Situation;

interface IReadOnlyHistory 
{
    public function getSituationBeforePly(plyNum:Int):Situation;
    public function getPly(plyNum:Int):RawPly;
}