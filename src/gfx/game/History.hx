package gfx.game;

import net.shared.variation.VariationPath;
import net.shared.variation.Variation;
import net.shared.converters.Notation;
import gfx.game.interfaces.IReadOnlyHistory;
import net.shared.board.Situation;
import net.shared.board.RawPly;

class History implements IReadOnlyHistory
{
    private var currentSituation:Situation;
    private var situationsPriorToPly:Array<Situation> = [];
    private var plys:Array<RawPly> = [];

    public function append(ply:RawPly) 
    {
        situationsPriorToPly.push(currentSituation);
        plys.push(ply);
        currentSituation = currentSituation.situationAfterRawPly(ply);
    }

    public function dropLast(cnt:Int) 
    {
        currentSituation = situationsPriorToPly[getMoveCount() - cnt];
        situationsPriorToPly = situationsPriorToPly.slice(0, -cnt);
        plys = plys.slice(0, -cnt);
    }

    public function dropAll() 
    {
        currentSituation = getStartingSituation();
        situationsPriorToPly = [];
        plys = [];
    }

    public function getShownSituationByPointer(pointer:Int):Situation 
    {
        if (getMoveCount() == pointer)
            return currentSituation.copy();
        else
            return situationsPriorToPly[pointer].copy();
    }

    public function getSituationBeforePly(plyNum:Int):Situation
    {
        return getShownSituationByPointer(plyNum - 1);
    }

    public function getSituationAfterPly(plyNum:Int):Situation
    {
        return getShownSituationByPointer(plyNum);
    }

    public function getPly(plyNum:Int):RawPly
    {
        return plys[plyNum - 1].copy();
    }

    public function getPlyStr(plyNum:Int, displayPlyNum:Bool, displayColor:Bool):String
    {
        var ply:RawPly = getPly(plyNum);
        var context:Situation = getSituationBeforePly(plyNum);
        var displayedPlyNum:Null<Int> = displayPlyNum? plyNum : null;

        return Notation.plyToNotation(ply, context, displayColor, displayedPlyNum);
    }

    public function getStartingSituation():Situation
    {
        if (Lambda.empty(situationsPriorToPly))
            return currentSituation.copy();
        else
            return getSituationBeforePly(1);
    }

    public function getMostRecentSituation():Situation 
    {
        return currentSituation.copy();
    }

    public function getMoveCount():Int
    {
        return plys.length;
    }

    public function getLine():Array<{ply:RawPly, situationAfter:Situation}>
    {
        var a:Array<{ply:RawPly, situationAfter:Situation}> = [];

        for (plyNum in 1...(getMoveCount()+1))
            a.push({ply: getPly(plyNum), situationAfter: getSituationAfterPly(plyNum)});

        return a;
    }

    public function asVariation():Variation
    {
        var variation:Variation = new Variation(getStartingSituation());
        var currentParentPath:VariationPath = VariationPath.root();

        for (ply in plys)
        {
            variation.addChild(currentParentPath, ply);
            currentParentPath = currentParentPath.childPath(0);
        }

        return variation;
    }
    
    public function new(startingSituation:Situation, plys:Array<RawPly>) 
    {
        currentSituation = startingSituation.copy();
        for (ply in plys)
            append(ply);
    }
}