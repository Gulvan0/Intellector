package gfx.live.interfaces;

import net.shared.utils.PlayerRef;
import struct.Variant;
import gfx.live.struct.ConstantGameParameters;
import net.shared.PieceColor;
import net.shared.board.Situation;
import net.shared.board.RawPly;
import net.shared.dataobj.TimeReservesData;

interface IReadOnlyGlobalState 
{
    public function getConstantParams():ConstantGameParameters;
    public function getOrientation():PieceColor;
    public function getShownSituation():Situation;
    public function getCurrentSituation():Situation;
    public function getHistory():IReadOnlyHistory;
    public function getShownMove():Int;
    public function getPlannedPremoves():Array<RawPly>;
    public function isOfferActive(kind:OfferKind, direction:OfferDirection):Bool;
    public function getTimeData():TimeReservesData;
    public function getPerMoveTimeRemainderData():IReadOnlyMsRemainders;
    public function getActiveTimerColor():PieceColor;
    public function getBoardInteractivityMode():InteractivityMode;
    public function getChatHistory():Array<ChatEntry>; 
    public function getStudyVariant():Variant; 
    public function isPlayerOnline(color:PieceColor):Bool; 
    public function getSpectatorRefs():Array<PlayerRef>; 
}