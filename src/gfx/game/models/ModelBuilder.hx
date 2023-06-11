package gfx.game.models;

import gfx.game.models.util.ChatEntry;
import gfx.game.models.util.History;
import net.shared.board.RawPly;
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
import gfx.game.models.util.MsRemaindersData;
import net.shared.PieceColor;
import net.shared.TimeControl;
import net.shared.dataobj.GameModelData;

using Lambda;

class ModelBuilder
{
    public static function fromGameModelData(data:GameModelData, ?orientationPariticipant:Null<PlayerRef>):Model
    {
        var orientation:PieceColor;
        if (orientationPariticipant != null && data.playerRefs[Black].equals(orientationPariticipant))
            orientation = Black;
        else
            orientation = White;

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
            model.timeControl = data.timeControl;
            model.playerRefs = data.playerRefs;
            model.elo = data.elo;
            model.startTimestamp = data.startTimestamp;
            model.orientation = orientation;
            model.playerOnline = data.playerOnline;
            model.spectatorRefs = data.activeSpectators;

            var constructRemainders:Bool = !data.legacyFlags.contains(FakeEventTimestamps) && !model.timeControl.isCorrespondence();

            model.outcome = null;
            model.history = new History(data.startingSituation, []);
            model.outgoingOfferActive = [for (color in PieceColor.createAll()) color => [for (kind in OfferKind.createAll()) kind => false]];
            model.perMoveTimeRemaindersData = constructRemainders? new MsRemaindersData(model.timeControl, model.startTimestamp, data.startingSituation.turnColor) : null;
            model.chatHistory = [];

            processEventLog(data.eventLog, model.history, model.outgoingOfferActive, model.perMoveTimeRemaindersData, model.chatHistory, x -> {model.outcome = x;}, model.playerRefs);

            model.shownMovePointer = model.getLineLength();
            
            model.deriveShownSituationFromOtherParams();
            model.deriveInteractivityModeFromOtherParams();

            return Spectation(model);
        }
        else if (botHandle != null)
        {
            var model:MatchVersusBotModel = new MatchVersusBotModel();

            model.gameID = data.gameID;
            model.timeControl = data.timeControl;
            model.playerRefs = data.playerRefs;
            model.startTimestamp = data.startTimestamp;
            model.orientation = orientation ?? playerColor;
            model.spectatorRefs = data.activeSpectators;
            model.plannedPremoves = [];
            model.opponentBot = BotFactory.build(botHandle);

            model.outcome = null;
            model.history = new History(data.startingSituation, []);
            model.perMoveTimeRemaindersData = model.timeControl.isCorrespondence()? null : new MsRemaindersData(model.timeControl, model.startTimestamp, data.startingSituation.turnColor);
            model.chatHistory = [];

            processEventLog(data.eventLog, model.history, null, model.perMoveTimeRemaindersData, model.chatHistory, x -> {model.outcome = x;}, data.playerRefs);

            model.shownMovePointer = model.getLineLength();

            model.deriveShownSituationFromOtherParams();
            model.deriveInteractivityModeFromOtherParams();

            return MatchVersusBot(model);
        }
        else
        {
            var model:MatchVersusPlayerModel = new MatchVersusPlayerModel();

            model.gameID = data.gameID;
            model.timeControl = data.timeControl;
            model.playerRefs = data.playerRefs;
            model.elo = data.elo;
            model.startTimestamp = data.startTimestamp;
            model.orientation = orientation ?? playerColor;
            model.opponentOnline = data.playerOnline[opposite(playerColor)];
            model.spectatorRefs = data.activeSpectators;
            model.plannedPremoves = [];

            model.outcome = null;
            model.history = new History(data.startingSituation, []);
            model.perMoveTimeRemaindersData = model.timeControl.isCorrespondence()? null : new MsRemaindersData(model.timeControl, model.startTimestamp, data.startingSituation.turnColor);
            model.chatHistory = [];

            var outgoingOfferActive = [for (color in PieceColor.createAll()) color => [for (kind in OfferKind.createAll()) kind => false]];

            processEventLog(data.eventLog, model.history, outgoingOfferActive, model.perMoveTimeRemaindersData, model.chatHistory, x -> {model.outcome = x;}, data.playerRefs);

            model.offerActive = [for (kind in OfferKind.createAll()) kind => [Incoming => outgoingOfferActive[opposite(playerColor)][kind], Outgoing => outgoingOfferActive[playerColor][kind]]];

            model.shownMovePointer = model.getLineLength();

            model.deriveShownSituationFromOtherParams();
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
                case Ply(ply):
                    history.append(ply);
                    if (perMoveTimeRemaindersData != null)
                        perMoveTimeRemaindersData.onMoveMade(item.ts);
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
                    if (perMoveTimeRemaindersData != null)
                        perMoveTimeRemaindersData.onTimeAdded(receiver);
                    chatHistory.push(Log(TIME_ADDED_MESSAGE(receiver)));
                case GameEnded(outcome):
                    outcomeSetter(outcome);
                    chatHistory.push(Log(CHATBOX_GAME_OVER_MESSAGE(outcome)));
                case Rollback(cancelledMovesCount):
                    history.dropLast(cancelledMovesCount);
                    if (perMoveTimeRemaindersData != null)
                        perMoveTimeRemaindersData.onRollback(cancelledMovesCount, item.ts);
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

        model.deriveShownSituationFromOtherParams();
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

        model.deriveShownSituationFromOtherParams();
        model.deriveInteractivityModeFromOtherParams();

        return model;
    }

    public static function fromExploredLine(startingSituation:Situation, plys:Array<RawPly>, shownMovePointer:Int):AnalysisBoardModel
    {
        var model:AnalysisBoardModel = new AnalysisBoardModel();

        var history:History = new History(startingSituation, plys);
        model.variation = history.asVariation();
        model.selectedBranch = model.variation.getFullMainlinePath();
        model.shownMovePointer = shownMovePointer;
        model.orientation = history.getShownSituationByPointer(shownMovePointer).turnColor;
        model.editorSituation = null;
        model.editorMode = null;
        model.exploredStudyInfo = null;

        model.deriveShownSituationFromOtherParams();
        model.deriveInteractivityModeFromOtherParams();

        return model;
    }
}