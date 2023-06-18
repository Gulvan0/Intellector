package gfx.game.behaviours;

import net.shared.board.Rules;
import gfx.scene.SceneManager;
import gfx.popups.ChallengeParamsDialog;
import net.shared.dataobj.ChallengeParams;
import net.shared.utils.UnixTimestamp;
import assets.Audio;
import dict.Dictionary;
import dict.Utils;
import gfx.popups.ShareDialog;
import utils.PortableIntellectorNotation;
import net.shared.board.RawPly;
import browser.Url;
import gfx.game.events.ChatboxEvent;
import gfx.game.events.ActionBarEvent;
import gfx.game.common.action_bar.ActionButton;
import gfx.game.events.PlyHistoryViewEvent;
import gfx.utils.PlyScrollType;
import gfx.game.events.GameboardEvent;
import net.shared.dataobj.OfferAction;
import net.shared.dataobj.OfferKind;
import net.shared.PieceColor;
import net.shared.dataobj.TimeReservesData;
import net.shared.ServerEvent;
import GlobalBroadcaster.GlobalEvent;
import gfx.game.events.PositionEditorEvent;
import gfx.game.events.VariationViewEvent;
import gfx.game.interfaces.IGameScreen;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.interfaces.IReadWriteGameRelatedModel;
import gfx.game.interfaces.IBehaviour;
import gfx.game.models.util.ChatEntry;

using gfx.game.models.CommonModelExtractors;

abstract class GameRelatedBehaviour extends BaseBehaviour
{
    private var model:IReadWriteGameRelatedModel;

    public abstract function handleGlobalEvent(event:GlobalEvent):Void;
    public abstract function handleGameboardEvent(event:GameboardEvent):Void;
    private abstract function onInvalidMove():Void;
    private abstract function onMoveAccepted(timestamp:UnixTimestamp):Void;
    private abstract function setPlayerOnlineStatus(playerColor:PieceColor, online:Bool):Void;
    private abstract function updateOfferStateDueToAction(offerSentBy:PieceColor, offer:OfferKind, action:OfferAction):Void;
    private abstract function customOnEntered():Void;
    private abstract function onOfferActionRequested(kind:OfferKind, action:OfferAction):Void;
    private abstract function updateBehaviourDueToTurnColorUpdate():Void;
    private abstract function isAutoscrollEnabled():Bool;
    private abstract function onScrolledToPastMove():Void;

    private function writeChatEntry(entry:ChatEntry) 
    {
        model.chatHistory.push(entry);
        modelUpdateHandler(EntryAddedToChatHistory);
    }

    /**
        timestampForTimeReset is null only for client-side rollbacks (such as when the move wasn't accepted by the server)
    **/
	private function rollback(plysToUndo:Int, timestampForTimeReset:Null<UnixTimestamp>)
	{
		var newMoveCount:Int = model.getLineLength() - plysToUndo;

		if (model.shownMovePointer > newMoveCount || isAutoscrollEnabled())
            applyScroll(Precise(newMoveCount));

		model.history.dropLast(plysToUndo);
		modelUpdateHandler(HistoryRollback);

		if (model.perMoveTimeRemaindersData != null)
		{
			model.perMoveTimeRemaindersData.onRollback(plysToUndo, timestampForTimeReset);
			modelUpdateHandler(TimeDataUpdated);
		}

		updateBehaviourDueToTurnColorUpdate();
	}

    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case InvalidMove:
                onInvalidMove();
            case Message(authorRef, message):
                writeChatEntry(PlayerMessage(authorRef, message));
            case SpectatorMessage(authorRef, message):
                writeChatEntry(SpectatorMessage(authorRef, message));
            case MoveAccepted(timestamp):
                onMoveAccepted(timestamp);
            case Move(ply, timestamp):
                model.history.append(ply);
                modelUpdateHandler(MoveAddedToHistory);

                var newMoveCount:Int = model.getLineLength();

                if (model.shownMovePointer == newMoveCount - 1 || isAutoscrollEnabled())
                {
                    model.shownMovePointer = newMoveCount;
                    modelUpdateHandler(ViewedMoveNumUpdated);

                    model.deriveShownSituationFromOtherParams();
                    modelUpdateHandler(ShownSituationUpdated);
                }
                
                if (model.perMoveTimeRemaindersData != null)
                {
                    model.perMoveTimeRemaindersData.onMoveMade(timestamp);
                    modelUpdateHandler(TimeDataUpdated);
                }

                updateBehaviourDueToTurnColorUpdate();
            case Rollback(plysToUndo, timestamp):
                rollback(plysToUndo, timestamp);
            case TimeAdded(receiver):
                model.perMoveTimeRemaindersData.onTimeAdded(receiver);
                modelUpdateHandler(TimeDataUpdated);
                writeChatEntry(Log(TIME_ADDED_MESSAGE(receiver)));
            case GameEnded(outcome, timestamp, newPersonalElo):
                for (offerKind in OfferKind.createAll())
                    for (offerSender in PieceColor.createAll())
                        if (model.isOutgoingOfferActive(offerSender, offerKind))
                            updateOfferStateDueToAction(offerSender, offerKind, Cancel);
                
                model.outcome = outcome;
                if (model.perMoveTimeRemaindersData != null)
                    model.perMoveTimeRemaindersData.recordTimeOnGameEnded(timestamp);
                modelUpdateHandler(GameEnded);

                var message:String;
                if (model.isPlayerParticipant())
                    message = Utils.getPlayerGameOverDialogMessage(outcome, model.getPlayerColor(), newPersonalElo);
                else
                    message = Utils.getSpectatorGameOverDialogMessage(outcome, model.playerRefs.copy());
                Dialogs.infoRaw(message, Dictionary.getPhrase(GAME_ENDED_DIALOG_TITLE));

                Audio.playSound("notify");
            case PlayerDisconnected(color):
                setPlayerOnlineStatus(color, false);
                modelUpdateHandler(PlayerOnlineStatusUpdated);
            case PlayerReconnected(color):
                setPlayerOnlineStatus(color, true);
                modelUpdateHandler(PlayerOnlineStatusUpdated);
            case NewSpectator(ref):
                model.spectatorRefs.push(ref);
                modelUpdateHandler(SpectatorListUpdated);
            case SpectatorLeft(ref):
                model.spectatorRefs.remove(ref);
                modelUpdateHandler(SpectatorListUpdated);
            case OfferActionPerformed(offerSentBy, offer, action):
                updateOfferStateDueToAction(offerSentBy, offer, action);
                writeChatEntry(Log(OFFER_ACTION_MESSAGE(offer, offerSentBy, action)));
            default:
        }
    }

    public function handleChatboxEvent(event:ChatboxEvent)
    {
        switch event 
        {
            case MessageSent(text):
                Networker.emitEvent(Message(text));

                writeChatEntry(PlayerMessage(LoginManager.getRef(), text));
        }
    }

    private function onSharePressed()
    {
        var gameLink:String = Url.getGameLink(model.gameID);
        var playedMoves:Array<RawPly> = model.getLine().map(x -> x.ply);
        var pin:String = PortableIntellectorNotation.serialize(model.getStartingSituation(), playedMoves, model.getPlayerRef(White), model.getPlayerRef(Black), model.getTimeControl(), model.getStartTimestamp(), model.getOutcome());

        var shareDialog:ShareDialog = new ShareDialog();
        shareDialog.initInGame(model.getShownSituation(), model.getOrientation(), gameLink, pin, model.getStartingSituation(), playedMoves);
        shareDialog.showShareDialog();
    }

    private function onResignPressed()
    {
        Networker.emitEvent(Resign);
    }
    
    private function onAbortPressed()
    {
        Networker.emitEvent(Resign);
    }
    
    private function onAddTimePressed()
    {
        Networker.emitEvent(AddTime);
    }
    
    private function onRematchPressed()
    {
        Networker.emitEvent(SimpleRematch);
    }
    
    private function onAnalyzePressed()
    {
        SceneManager.getScene().toScreen(AnalysisForLine(model.getStartingSituation(), model.getLine().map(x -> x.ply), model.getShownMovePointer()));
    }

    public function handleVariationViewEvent(event:VariationViewEvent)
    {
        throw 'VariationViewEvent occured in game related behaviour: $event';
    }

    public function handlePositionEditorEvent(event:PositionEditorEvent)
    {
        throw 'PositionEditorEvent occured in game related behaviour: $event';
    }

	private function onEditPositionPressed() 
    {
        throw 'EditPosition pressed in game related behaviour';
    }

	private function onViewReportPressed() 
    {
        throw 'ViewReport pressed in game related behaviour';
    }

    public function new(model:IReadWriteGameRelatedModel)
    {
        super(model);
        this.model = model;
    }
}