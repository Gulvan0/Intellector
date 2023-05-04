package gfx.game.models;

import net.shared.utils.UnixTimestamp;
import gfx.game.interfaces.IReadOnlySpectationModel;
import net.shared.board.Situation;
import net.shared.Outcome;
import net.shared.EloValue;
import net.shared.PieceColor;
import utils.TimeControl;
import net.shared.utils.PlayerRef;
import gfx.game.interfaces.IReadOnlyMsRemainders;
import gfx.game.struct.MsRemaindersData;
import net.shared.board.RawPly;
import gfx.game.interfaces.IReadOnlyHistory;
import net.shared.dataobj.OfferKind;

class SpectationModel implements IReadOnlySpectationModel
{
    public var gameID:Int;
    public var timeControl:TimeControl;
    public var playerRefs:Map<PieceColor, PlayerRef>;
    public var elo:Null<Map<PieceColor, EloValue>>;
    public var outcome:Null<Outcome>;
    public var startTimestamp:Null<UnixTimestamp>;
    
    public var orientation:PieceColor;
    public var history:History;
    public var shownMovePointer:Int;
    public var outgoingOfferActive:Map<PieceColor, Map<OfferKind, Bool>>;
    public var perMoveTimeRemaindersData:Null<MsRemaindersData>;
    public var activeTimerColor:Null<PieceColor>;
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
        return playerRefs.get(color);
    }

    public function isRated():Bool
    {
        return elo != null;
    }

    public function getELO(color:PieceColor):EloValue
    {
        return isRated()? elo.get(color) : null;
    }

    public function hasEnded():Bool
    {
        return outcome != null;
    }

    public function getOutcome():Outcome
    {
        return outcome;
    }

    public function getStartTimestamp():UnixTimestamp
    {
        return startTimestamp;
    }

    public function getOrientation():PieceColor
    {
        return orientation;
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

    public function getMsRemainders():Null<IReadOnlyMsRemainders>
    {
        return perMoveTimeRemaindersData;
    }

    public function getActiveTimerColor():Null<PieceColor>
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

    //Additional methods to unify with IReadOnlyGameRelatedModel
    
    public function getPlayerColor():Null<PieceColor>
    {
        return null;
    }

    //Additional methods to unify with IReadOnlyGenericModel
    
    public function getLineLength():Int
    {
        return getHistory().getMoveCount();
    }

    public function getLine():Array<{ply:RawPly, situationAfter:Situation}>
    {
        return getHistory().getLine();
    }

    public function getStartingSituation():Situation
    {
        return getHistory().getStartingSituation();
    }

	public function getMostRecentSituation():Situation 
    {
		return getHistory().getMostRecentSituation();
	}

    public function new()
    {

    }
}