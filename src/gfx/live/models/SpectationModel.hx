package gfx.live.models;

import gfx.live.interfaces.IReadOnlySpectationModel;
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

class SpectationModel implements IReadOnlySpectationModel
{
    public var gameID:Int;
    public var timeControl:TimeControl;
    public var playerRefs:Map<PieceColor, PlayerRef>;
    public var elo:Null<Map<PieceColor, EloValue>>;
    public var outcome:Null<Outcome>;
    public var datetime:Null<Date>;
    
    public var orientation:PieceColor;
    public var history:History;
    public var shownMovePointer:Int;
    public var outgoingOfferActive:Map<PieceColor, Map<OfferKind, Bool>>;
    public var timeData:TimeReservesData;
    public var perMoveTimeRemaindersData:MsRemaindersData;
    public var activeTimerColor:PieceColor;
    public var boardInteractivityMode:InteractivityMode;

    public var chatHistory:Array<ChatEntry>;
    public var playerOnline:Map<PieceColor, Bool>;
    public var spectatorRefs:Array<PlayerRef>;   

    public function getGameID():Int
    {
        return gameID;
    }

    public function getTimeControl():TimeControl
    {
        return timeControl.copy();
    }

    public function getPlayerRef(color:PieceColor):PlayerRef
    {
        return gameID;
    }

    public function isRated():Bool
    {
        return elo != null;
    }

    public function getELO(color:PieceColor):EloValue
    {
        return elo.get(color);
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

    public function getOrientation():PieceColor
    {
        return startingSituation.copy();
    }

    public function getShownSituation():Situation
    {
        return history.getShownSituationByPointer(shownMovePointer);
    }

    public function getHistory():IReadOnlyHistory
    {
        return history;
    }

    public function getShownMovePointer():Int
    {
        return shownMovePointer;
    }

    public function isOutgoingOfferActive(color:PieceColor, kind:OfferKind):Bool
    {
        return outgoingOfferActive[color][kind];
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

    public function getChatHistory():Array<ChatEntry>
    {
        return chatHistory.copy();
    }

    public function isPlayerOnline(color:PieceColor):Bool
    {
        return playerOnline[color];
    }

    public function getSpectators():Array<PlayerRef>
    {
        return spectatorRefs.copy();
    }
}