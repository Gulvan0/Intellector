package gfx.live.models;

import gfx.live.interfaces.IReadOnlyMatchVersusBotModel;
import engine.Bot;
import net.shared.board.Situation;
import net.shared.Outcome;
import net.shared.EloValue;
import net.shared.PieceColor;
import utils.TimeControl;
import net.shared.utils.PlayerRef;
import gfx.live.interfaces.IReadOnlyMsRemainders;
import gfx.live.struct.MsRemaindersData;
import net.shared.dataobj.TimeReservesData;
import net.shared.board.RawPly;
import gfx.live.interfaces.IReadOnlyHistory;

class MatchVersusBotModel implements IReadOnlyMatchVersusBotModel
{
    private var gameID:Int;
    private var opponentBot:Bot;
    private var timeControl:TimeControl;
    private var playerRefs:Map<PieceColor, PlayerRef>;
    private var outcome:Null<Outcome>;
    private var datetime:Null<Date>;
    private var startingSituation:Situation;
    
    private var orientation:PieceColor;
    private var shownSituation:Situation;
    private var currentSituation:Situation;
    private var history:History;
    private var shownMove:Int;
    private var plannedPremoves:Array<RawPly>;
    private var timeData:TimeReservesData;
    private var perMoveTimeRemaindersData:MsRemaindersData;
    private var activeTimerColor:PieceColor;
    private var boardInteractivityMode:InteractivityMode;

    private var chatHistory:Array<ChatEntry>;
    private var spectatorRefs:Array<PlayerRef>;

    public function getGameID():Int
    {
        return gameID;
    }

    public function getOpponentBot():Bot
    {
        return opponentBot;
    }

    public function getTimeControl():TimeControl
    {
        return timeControl.copy();
    }

    public function getPlayerRef(color:PieceColor):PlayerRef
    {
        return gameID;
    }

    public function hasEnded():Bool
    {
        return outcome != null;
    }

    public function getOutcome():Outcome
    {
        return outcome;
    }

    public function getDateTime():Date
    {
        return datetime;
    }

    public function getStartingSituation():Situation
    {
        return startingSituation.copy();
    }

    public function getOrientation():PieceColor
    {
        return startingSituation.copy();
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
        return plannedPremoves.map(x -> x.copy());
    }

    public function getTimeReservesData():TimeReservesData
    {
        return timeData.copy();
    }

    public function getMsRemainders():IReadOnlyMsRemainders
    {
        return perMoveTimeRemaindersData;
    }

    public function getActiveTimerColor():PieceColor
    {
        return activeTimerColor;
    }

    public function getBoardInteractivityMode():InteractivityMode
    {
        return boardInteractivityMode;
    }

    public function getChatHistory():PieceColor
    {
        return chatHistory.copy();
    }

    public function getSpectators():Array<PlayerRef>
    {
        return spectatorRefs.copy();
    }
}