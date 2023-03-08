package gameboard_revamped.interfaces;

import net.shared.PieceColor;
import net.shared.board.Situation;
import net.shared.board.RawPly;
import net.shared.dataobj.TimeReservesData;

interface IReadOnlyGlobalState 
{
    public function getOrientation():PieceColor;
    public function getShownSituation():Situation;
    public function getCurrentSituation():Situation;
    public function getHistory():IReadOnlyHistory;
    public function getShownMove():Int;
    public function getPlannedPremoves():Array<RawPly>;
    public function isOfferActive(kind:OfferKind, direction:OfferDirection):Bool;
    public function getTimeData():TimeReservesData;
    public function getBoardInteractivityMode():InteractivityMode;
}