package gfx.game.interfaces;

import net.shared.board.RawPly;
import net.shared.board.Situation;

interface IReadOnlyHistory 
{
    public function getSituationBeforePly(plyNum:Int):Situation;
    public function getSituationAfterPly(plyNum:Int):Situation;
    public function getPly(plyNum:Int):RawPly;
    public function getPlyStr(plyNum:Int, displayPlyNum:Bool, displayColor:Bool):String;
    public function getStartingSituation():Situation;
    public function getMostRecentSituation():Situation;
    public function getMoveCount():Int;
    public function getLine():Array<{ply:RawPly, situationAfter:Situation}>;
}