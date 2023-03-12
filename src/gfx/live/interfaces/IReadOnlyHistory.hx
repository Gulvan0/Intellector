package gfx.live.interfaces;

import net.shared.board.RawPly;
import net.shared.board.Situation;

interface IReadOnlyHistory 
{
    public function getSituationBeforePly(plyNum:Int):Situation;
    public function getPly(plyNum:Int):RawPly;
}