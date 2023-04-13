package gfx.live;

import gfx.live.interfaces.IReadOnlyHistory;
import net.shared.board.Situation;
import net.shared.board.RawPly;

class History implements IReadOnlyHistory
{
    private var situationsPriorToPly:Array<Situation> = [];
    private var plys:Array<RawPly> = [];

    public static function fromPlayedMoves(startingSituation:Situation, plys:Array<RawPly>):History
    {
        var history:History = new History();

        var sit = startingSituation.copy();
        for (ply in plys)
        {
            history.append(sit, ply);
            sit = sit.situationAfterRawPly(ply);
        }

        return history;
    }

    public function append(priorSituation:Situation, ply:RawPly) 
    {
        situationsPriorToPly.push(priorSituation.copy());
        plys.push(ply.copy());
    }

    public function dropLast(cnt:Int) 
    {
        situationsPriorToPly = situationsPriorToPly.slice(0, -cnt);
        plys = plys.slice(0, -cnt);
    }

    public function dropAll() 
    {
        situationsPriorToPly = [];
        plys = [];
    }

    public function getSituationBeforePly(plyNum:Int):Situation
    {
        return situationsPriorToPly[plyNum - 1].copy();
    }

    public function getPly(plyNum:Int):RawPly
    {
        return plys[plyNum - 1].copy();
    }
    
    public function new() 
    {

    }
}