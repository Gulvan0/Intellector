package gfx.live.interfaces;

import engine.Bot;
import utils.TimeControl;
import net.shared.Outcome;
import net.shared.board.Situation;
import net.shared.board.RawPly;
import net.shared.dataobj.TimeReservesData;
import net.shared.PieceColor;
import net.shared.utils.PlayerRef;

interface IReadOnlyMatchVersusBotModel 
{
    public function getGameID():Int;
    public function getOpponentBot():Bot;
    public function getTimeControl():TimeControl;
    public function getPlayerRef(color:PieceColor):PlayerRef;
    public function hasEnded():Bool;
    public function getOutcome():Outcome;
    public function getDateTime():Date;
    public function getStartingSituation():Situation;
    public function getOrientation():PieceColor;
    public function getShownSituation():Situation;
    public function getCurrentSituation():Situation;
    public function getHistory():IReadOnlyHistory;
    public function getShownMove():Int;
    public function getPlannedPremoves():Array<RawPly>;
    public function getTimeReservesData():TimeReservesData;
    public function getMsRemainders():IReadOnlyMsRemainders;
    public function getActiveTimerColor():PieceColor;
    public function getBoardInteractivityMode():InteractivityMode;
    public function getChatHistory():Array<ChatEntry>;
    public function getSpectators():Array<PlayerRef>;

}