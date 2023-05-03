package gfx.live.models;

import net.shared.utils.PlayerRef;
import net.shared.dataobj.OfferDirection;
import engine.BotFactory;
import net.shared.Constants;
import net.shared.Outcome;
import net.shared.utils.UnixTimestamp;
import net.shared.dataobj.GameEventLogEntry;
import net.shared.dataobj.OfferKind;
import net.shared.dataobj.TimeReservesData;
import gfx.live.struct.MsRemaindersData;
import net.shared.PieceColor;
import utils.TimeControl;
import net.shared.dataobj.GameModelData;

using Lambda;

class ModelBuilder
{
    public static function fromGameModelData(data:GameModelData, ?orientation:PieceColor = White):Model
    {
        var gameEnded:Bool = data.eventLog.exists(item -> item.entry.match(GameEnded(_)));
        var playerColor:Null<PieceColor> = LoginManager.isPlayer(data.playerRefs[White])? White : LoginManager.isPlayer(data.playerRefs[Black])? Black : null;

        var botHandle:Null<String> = switch [data.playerRefs[White].concretize(), data.playerRefs[Black].concretize()] 
        {
            case [Bot(handle), _]: handle;
            case [_, Bot(handle)]: handle;
            default: null;
        }

        if (playerColor == null || gameEnded)
        {
            var model:SpectationModel = new SpectationModel();

            model.gameID = data.gameID;
            model.timeControl = new TimeControl(data.timeControl.startSecs, data.timeControl.bonusSecs);
            model.playerRefs = data.playerRefs;
            model.elo = data.elo;
            model.startTimestamp = data.startTimestamp;
            model.orientation = orientation;
            model.playerOnline = data.playerOnline;
            model.spectatorRefs = data.activeSpectators;

            model.outcome = null;
            model.history = new History(data.startingSituation, []);
            model.outgoingOfferActive = [for (color in PieceColor.createAll()) color => [for (kind in OfferKind.createAll()) kind => false]];
            model.perMoveTimeRemaindersData = model.timeControl.isCorrespondence()? null : new MsRemaindersData(model.timeControl, model.startTimestamp);
            model.chatHistory = [];

            processEventLog(data.eventLog, model.history, model.outgoingOfferActive, model.perMoveTimeRemaindersData, model.chatHistory, x -> {model.outcome = x;}, model.playerRefs);

            var totalMoves:Int = model.getLineLength();
            model.boardInteractivityMode = NotInteractive;
            model.shownMovePointer = totalMoves;
            if (gameEnded || model.timeControl.isCorrespondence() || totalMoves < 2)
                model.activeTimerColor = null;
            else
                model.activeTimerColor = totalMoves % 2 == 0? White : Black;

            return Spectation(model);
        }
        else if (botHandle != null)
        {
            var model:MatchVersusBotModel = new MatchVersusBotModel();

            model.gameID = data.gameID;
            model.timeControl = new TimeControl(data.timeControl.startSecs, data.timeControl.bonusSecs);
            model.playerRefs = data.playerRefs;
            model.startTimestamp = data.startTimestamp;
            model.orientation = orientation;
            model.spectatorRefs = data.activeSpectators;
            model.plannedPremoves = [];
            model.opponentBot = BotFactory.build(botHandle);

            model.outcome = null;
            model.history = new History(data.startingSituation, []);
            model.perMoveTimeRemaindersData = model.timeControl.isCorrespondence()? null : new MsRemaindersData(model.timeControl, model.startTimestamp);
            model.chatHistory = [];

            processEventLog(data.eventLog, model.history, null, model.perMoveTimeRemaindersData, model.chatHistory, x -> {model.outcome = x;}, data.playerRefs);

            var totalMoves:Int = model.getLineLength();
            model.boardInteractivityMode = NotInteractive;
            model.shownMovePointer = totalMoves;
            if (gameEnded || model.timeControl.isCorrespondence() || totalMoves < 2)
                model.activeTimerColor = null;
            else
                model.activeTimerColor = totalMoves % 2 == 0? White : Black;

            return MatchVersusBot(model);
        }
        else
        {
            var model:MatchVersusPlayerModel = new MatchVersusPlayerModel();

            model.gameID = data.gameID;
            model.timeControl = new TimeControl(data.timeControl.startSecs, data.timeControl.bonusSecs);
            model.playerRefs = data.playerRefs;
            model.elo = data.elo;
            model.startTimestamp = data.startTimestamp;
            model.orientation = orientation;
            model.opponentOnline = data.playerOnline[opposite(playerColor)];
            model.spectatorRefs = data.activeSpectators;
            model.plannedPremoves = [];

            model.outcome = null;
            model.history = new History(data.startingSituation, []);
            model.perMoveTimeRemaindersData = model.timeControl.isCorrespondence()? null : new MsRemaindersData(model.timeControl, model.startTimestamp);
            model.chatHistory = [];

            var outgoingOfferActive = [for (color in PieceColor.createAll()) color => [for (kind in OfferKind.createAll()) kind => false]];

            processEventLog(data.eventLog, model.history, outgoingOfferActive, model.perMoveTimeRemaindersData, model.chatHistory, x -> {model.outcome = x;}, data.playerRefs);

            model.offerActive = [for (kind in OfferKind.createAll()) kind => [Incoming => outgoingOfferActive[opposite(playerColor)][kind], Outgoing => outgoingOfferActive[playerColor][kind]]];

            var totalMoves:Int = model.getLineLength();
            model.boardInteractivityMode = NotInteractive;
            model.shownMovePointer = totalMoves;
            if (gameEnded || model.timeControl.isCorrespondence() || totalMoves < 2)
                model.activeTimerColor = null;
            else
                model.activeTimerColor = totalMoves % 2 == 0? White : Black;

            return MatchVersusPlayer(model);
        }
    }

    private static function processEventLog(eventLog:Array<{ts:UnixTimestamp, entry:GameEventLogEntry}>, history:History, outgoingOfferActive:Null<Map<PieceColor, Map<OfferKind, Bool>>>, perMoveTimeRemaindersData:Null<MsRemaindersData>, chatHistory:Array<ChatEntry>, outcomeSetter:Outcome->Void, playerRefs:Map<PieceColor, PlayerRef>)
    {
        for (item in eventLog)
        {
            switch item.entry 
            {
                case Ply(ply, whiteMsAfter, blackMsAfter):
                    history.append(ply);
                    if (perMoveTimeRemaindersData != null)
                        perMoveTimeRemaindersData.append(new TimeReservesData(whiteMsAfter / 1000, blackMsAfter / 1000, item.ts));
                case OfferSent(kind, sentBy):
                    if (outgoingOfferActive != null)
                        outgoingOfferActive[sentBy][kind] = true;
                    chatHistory.push(Log(OFFER_SENT_MESSAGE(kind, sentBy)));
                case OfferCancelled(kind, sentBy):
                    if (outgoingOfferActive != null)
                        outgoingOfferActive[sentBy][kind] = false;
                    chatHistory.push(Log(OFFER_CANCELLED_MESSAGE(kind, sentBy)));
                case OfferAccepted(kind, sentBy):
                    if (outgoingOfferActive != null)
                        outgoingOfferActive[sentBy][kind] = false;
                    chatHistory.push(Log(OFFER_ACCEPTED_MESSAGE(kind, sentBy)));
                case OfferDeclined(kind, sentBy):
                    if (outgoingOfferActive != null)
                        outgoingOfferActive[sentBy][kind] = false;
                    chatHistory.push(Log(OFFER_DECLINED_MESSAGE(kind, sentBy)));
                case Message(sentBy, text):
                    if (playerRefs.has(sentBy))
                        chatHistory.push(PlayerMessage(sentBy, text));
                    else
                        chatHistory.push(SpectatorMessage(sentBy, text));
                case TimeAdded(receiver):
                    perMoveTimeRemaindersData.addTime(receiver, Constants.msAddedByOpponent / 1000);
                    chatHistory.push(Log(TIME_ADDED_MESSAGE(receiver)));
                case GameEnded(outcome):
                    outcomeSetter(outcome);
                    chatHistory.push(Log(CHATBOX_GAME_OVER_MESSAGE(outcome)));
                default:
            }
        }
    }
}