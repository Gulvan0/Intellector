package gfx.game.models;

import engine.Bot;
import net.shared.dataobj.ChallengeParams;
import net.shared.board.Rules;
import net.shared.board.Situation;
import net.shared.variation.Variation;
import net.shared.variation.VariationPath;
import gfx.game.interfaces.IReadOnlyHistory;
import net.shared.dataobj.StudyInfo;
import net.shared.utils.PlayerRef;
import net.shared.dataobj.OfferDirection;
import engine.BotFactory;
import net.shared.Constants;
import net.shared.Outcome;
import net.shared.utils.UnixTimestamp;
import net.shared.dataobj.GameEventLogEntry;
import net.shared.dataobj.OfferKind;
import net.shared.dataobj.TimeReservesData;
import gfx.game.struct.MsRemaindersData;
import net.shared.PieceColor;
import net.shared.TimeControl;
import net.shared.dataobj.GameModelData;

using Lambda;

class ModelBuilder
{
    public static function fromGameModelData(data:GameModelData, ?orientation:Null<PieceColor>):Model
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
            model.timeControl = new TimeControl(data.timeControl.startSecs, data.timeControl.incrementSecs);
            model.playerRefs = data.playerRefs;
            model.elo = data.elo;
            model.startTimestamp = data.startTimestamp;
            model.orientation = orientation ?? White;
            model.playerOnline = data.playerOnline;
            model.spectatorRefs = data.activeSpectators;

            model.outcome = null;
            model.history = new History(data.startingSituation, []);
            model.outgoingOfferActive = [for (color in PieceColor.createAll()) color => [for (kind in OfferKind.createAll()) kind => false]];
            model.perMoveTimeRemaindersData = model.timeControl.isCorrespondence()? null : new MsRemaindersData(model.timeControl, model.startTimestamp);
            model.chatHistory = [];

            processEventLog(data.eventLog, model.history, model.outgoingOfferActive, model.perMoveTimeRemaindersData, model.chatHistory, x -> {model.outcome = x;}, model.playerRefs);

            var totalMoves:Int = model.getLineLength();
            model.shownMovePointer = totalMoves;
            if (gameEnded || model.timeControl.isCorrespondence() || totalMoves < 2)
                model.activeTimerColor = null;
            else
                model.activeTimerColor = totalMoves % 2 == 0? White : Black;
            
            model.deriveInteractivityModeFromOtherParams();

            return Spectation(model);
        }
        else if (botHandle != null)
        {
            var model:MatchVersusBotModel = new MatchVersusBotModel();

            model.gameID = data.gameID;
            model.timeControl = new TimeControl(data.timeControl.startSecs, data.timeControl.incrementSecs);
            model.playerRefs = data.playerRefs;
            model.startTimestamp = data.startTimestamp;
            model.orientation = orientation ?? playerColor;
            model.spectatorRefs = data.activeSpectators;
            model.plannedPremoves = [];
            model.opponentBot = BotFactory.build(botHandle);

            model.outcome = null;
            model.history = new History(data.startingSituation, []);
            model.perMoveTimeRemaindersData = model.timeControl.isCorrespondence()? null : new MsRemaindersData(model.timeControl, model.startTimestamp);
            model.chatHistory = [];

            processEventLog(data.eventLog, model.history, null, model.perMoveTimeRemaindersData, model.chatHistory, x -> {model.outcome = x;}, data.playerRefs);

            var totalMoves:Int = model.getLineLength();
            model.shownMovePointer = totalMoves;
            if (gameEnded || model.timeControl.isCorrespondence() || totalMoves < 2)
                model.activeTimerColor = null;
            else
                model.activeTimerColor = totalMoves % 2 == 0? White : Black;

            model.deriveInteractivityModeFromOtherParams();

            return MatchVersusBot(model);
        }
        else
        {
            var model:MatchVersusPlayerModel = new MatchVersusPlayerModel();

            model.gameID = data.gameID;
            model.timeControl = new TimeControl(data.timeControl.startSecs, data.timeControl.incrementSecs);
            model.playerRefs = data.playerRefs;
            model.elo = data.elo;
            model.startTimestamp = data.startTimestamp;
            model.orientation = orientation ?? playerColor;
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
            model.shownMovePointer = totalMoves;
            if (gameEnded || model.timeControl.isCorrespondence() || totalMoves < 2)
                model.activeTimerColor = null;
            else
                model.activeTimerColor = totalMoves % 2 == 0? White : Black;

            model.deriveInteractivityModeFromOtherParams();

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
                case OfferActionPerformed(kind, sentBy, action):
                    if (outgoingOfferActive != null)
                        outgoingOfferActive[sentBy][kind] = action.match(Create);
                    chatHistory.push(Log(OFFER_ACTION_MESSAGE(kind, sentBy, action)));
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

    public static function cleanAnalysis():AnalysisBoardModel
    {
        var model:AnalysisBoardModel = new AnalysisBoardModel();

        model.variation = new Variation(Situation.defaultStarting());
        model.selectedBranch = VariationPath.root();
        model.shownMovePointer = 0;
        model.orientation = White;
        model.editorSituation = null;
        model.editorMode = null;
        model.exploredStudyInfo = null;

        model.deriveInteractivityModeFromOtherParams();

        return model;
    }

    public static function fromStudyInfo(studyInfo:StudyInfo):AnalysisBoardModel
    {
        var model:AnalysisBoardModel = new AnalysisBoardModel();

        model.variation = studyInfo.plainVariation.toVariation();
        model.selectedBranch = VariationPath.root();
        model.shownMovePointer = 0;
        model.orientation = model.variation.rootNode().situation.turnColor;
        model.editorSituation = null;
        model.editorMode = null;
        model.exploredStudyInfo = null;

        model.deriveInteractivityModeFromOtherParams();

        return model;
    }

    public static function fromExploredLine(history:IReadOnlyHistory, shownMovePointer:Int):AnalysisBoardModel
    {
        var model:AnalysisBoardModel = new AnalysisBoardModel();

        model.variation = history.asVariation();
        model.selectedBranch = model.variation.getFullMainlinePath();
        model.shownMovePointer = shownMovePointer;
        model.orientation = history.getShownSituationByPointer(shownMovePointer).turnColor;
        model.editorSituation = null;
        model.editorMode = null;
        model.exploredStudyInfo = null;

        model.deriveInteractivityModeFromOtherParams();

        return model;
    }
}