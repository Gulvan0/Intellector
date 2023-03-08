package gameboard_revamped;

import net.shared.PieceColor;
import net.shared.dataobj.TimeReservesData;
import net.shared.board.RawPly;
import gameboard_revamped.interfaces.IReadOnlyGlobalState;
import gameboard_revamped.interfaces.IReadOnlyHistory;
import net.shared.board.Situation;

class GlobalGameState implements IReadOnlyGlobalState
{
    public var orientation:PieceColor;
    public var shownSituation:Situation;
    public var currentSituation:Situation;
    public var history:History;
    public var shownMove:Int;
    public var plannedPremoves:Array<RawPly>;
    public var offerActive:Map<OfferKind, Map<OfferDirection, Bool>>;
    public var timeData:TimeReservesData;
    public var boardInteractivityMode:InteractivityMode;

    public function getOrientation():PieceColor
    {
        return orientation;
    }

    public function getShownSituation():Situation
    {
        return shownSituation.copy();
    }

    public function getCurrentSituation():Situation
    {
        return currentSituation.copy();
    }

    public function getHistory():IReadOnlyHistory
    {
        return history;
    }

    public function getShownMove():Int
    {
        return shownMove;
    }

    public function getPlannedPremoves():Array<RawPly>
    {
        return plannedPremoves.map(p -> p.copy());
    }

    public function isOfferActive(kind:OfferKind, direction:OfferDirection):Bool
    {
        return offerActive.get(kind).get(direction);
    }

    public function getTimeData():TimeReservesData
    {
        return timeData.copy();
    }

    public function getBoardInteractivityMode():InteractivityMode
    {
        return boardInteractivityMode;
    }

    public function new() 
    {
        
    }
}