package gfx.game.models;

import gfx.game.interfaces.IReadWriteGameRelatedModel;
import net.shared.board.Hex;
import net.shared.board.HexCoords;
import net.shared.board.Rules;
import net.shared.utils.UnixTimestamp;
import gfx.game.interfaces.IReadOnlyGenericModel;
import gfx.game.interfaces.IReadOnlyGameRelatedModel;
import gfx.game.interfaces.IReadOnlyMatchVersusPlayerModel;
import net.shared.board.Situation;
import net.shared.Outcome;
import net.shared.EloValue;
import net.shared.PieceColor;
import net.shared.TimeControl;
import net.shared.utils.PlayerRef;
import gfx.game.interfaces.IReadOnlyMsRemainders;
import gfx.game.struct.MsRemaindersData;
import net.shared.board.RawPly;
import gfx.game.interfaces.IReadOnlyHistory;
import net.shared.dataobj.OfferKind;
import net.shared.dataobj.OfferDirection;

class MatchVersusPlayerModel implements IReadWriteGameRelatedModel implements IReadOnlyMatchVersusPlayerModel
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
    public var plannedPremoves:Array<RawPly>;
    public var offerActive:Map<OfferKind, Map<OfferDirection, Bool>>;
    public var perMoveTimeRemaindersData:Null<MsRemaindersData>;
    public var activeTimerColor:Null<PieceColor>;
    public var boardInteractivityMode:InteractivityMode;

    public var chatHistory:Array<ChatEntry>;
    public var opponentOnline:Bool;
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
        var actualShownSituation:Situation = history.getShownSituationByPointer(shownMovePointer);
        for (premovePly in plannedPremoves)
            actualShownSituation.performRawPly(premovePly);
        return actualShownSituation;
    }

    public function getHistory():IReadOnlyHistory
    {
        return history;
    }

    public function getShownMovePointer():Int
    {
        return shownMovePointer;
    }

    public function getPlannedPremoves():Array<RawPly>
    {
        return plannedPremoves.map(x -> x.copy());
    }

    public function isOfferActive(kind:OfferKind, direction:OfferDirection):Bool
    {
        return offerActive[kind][direction];
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

    public function isOpponentOnline():Bool
    {
        return opponentOnline;
    }

    public function getSpectators():Array<PlayerRef>
    {
        return spectatorRefs.copy();
    }

    //Additional methods to unify with IReadOnlyGameRelatedModel
    
    public function getPlayerColor():Null<PieceColor>
    {
        if (LoginManager.isPlayer(getPlayerRef(White)))
            return White;
        else
            return Black;
    }

    public function isOutgoingOfferActive(color:PieceColor, kind:OfferKind):Bool
    {
        if (getPlayerColor() == color)
            return isOfferActive(kind, Outgoing);
        else
            return isOfferActive(kind, Incoming);
    }
    
    public function isPlayerOnline(color:PieceColor):Bool
    {
        if (getPlayerColor() == color)
            return true;
        else
            return isOpponentOnline();
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

    public function deriveInteractivityModeFromOtherParams()
    {
        var shownSituation:Situation = getShownSituation();

        if (!hasEnded() && (getPlayerColor() == shownSituation.turnColor || Preferences.premoveEnabled.get()))
        {
            var allowedDestinationsRetriever:HexCoords->Array<HexCoords> = (departureCoords:HexCoords) -> {
                var departureHex:Hex = shownSituation.get(departureCoords);
                if (departureHex.color() != shownSituation.turnColor)
                    return [];
                else
                    return Rules.getPossibleDestinations(departureCoords, shownSituation.get, false);
            };
            boardInteractivityMode = PlySelection(allowedDestinationsRetriever);
        }
        else
            boardInteractivityMode = NotInteractive;
    }

    public function new()
    {

    }
}