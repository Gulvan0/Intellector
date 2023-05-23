package gfx.game.behaviours;

import net.shared.dataobj.OfferAction;
import GlobalBroadcaster.GlobalEvent;
import gfx.game.interfaces.IGameScreen;
import gfx.popups.ShareDialog;
import net.shared.board.RawPly;
import browser.Url;
import net.shared.dataobj.OfferKind;
import net.shared.PieceColor;
import net.shared.PieceColor.opposite;
import gfx.game.common.action_bar.ActionButton;
import net.shared.dataobj.OfferDirection;
import gfx.game.models.MatchVersusPlayerModel;
import net.shared.ServerEvent;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.events.GameboardEvent;
import gfx.game.events.ChatboxEvent;
import gfx.game.events.ActionBarEvent;
import gfx.game.events.PlyHistoryViewEvent;
import gfx.game.events.VariationViewEvent;
import gfx.game.events.PositionEditorEvent;
import gfx.game.interfaces.IBehaviour;
import utils.PortableIntellectorNotation;

class WaitingRealOpponentMoveNoPremoves implements IBehaviour 
{
	private var model:MatchVersusPlayerModel;
	private var modelUpdateHandler:ModelUpdateEvent->Void;
	private var screenRef:IGameScreen;

	public function handleNetEvent(event:ServerEvent)
	{
		switch event 
		{
			case InvalidMove:
				Dialogs.alert(INVALID_MOVE_DIALOG_MESSAGE, INVALID_MOVE_DIALOG_TITLE);

				model.history.dropLast(1);

				var newMoveCount:Int = model.getLineLength();

				if (model.shownMovePointer > newMoveCount || Preferences.autoScrollOnMove.get().match(Always | OwnGameOnly))
				{
					model.shownMovePointer = newMoveCount;
					modelUpdateHandler(ViewedMoveNumUpdated);
				}

				modelUpdateHandler(HistoryRollback);
			case Message(authorRef, message):
				model.chatHistory.push(PlayerMessage(authorRef, message));
				modelUpdateHandler(EntryAddedToChatHistory);
			case SpectatorMessage(authorRef, message):
				model.chatHistory.push(SpectatorMessage(authorRef, message));
				modelUpdateHandler(EntryAddedToChatHistory);
			case MoveAccepted(timeData):
				if (timeData != null)
				{
					model.perMoveTimeRemaindersData.modifyLast(timeData);
					modelUpdateHandler(TimeDataUpdated);
				}
			case Move(ply, timeData):
				model.history.append(ply);
				modelUpdateHandler(MoveAddedToHistory);

				var newMoveCount:Int = model.getLineLength();

				if (model.shownMovePointer == newMoveCount - 1 || Preferences.autoScrollOnMove.get().match(Always | OwnGameOnly))
				{
					model.shownMovePointer = newMoveCount;
					modelUpdateHandler(ViewedMoveNumUpdated);
				}
				
				if (timeData != null)
				{
					model.perMoveTimeRemaindersData.append(timeData);
					model.activeTimerColor = newMoveCount < 2? null : newMoveCount % 2 == 0? White : Black;
					modelUpdateHandler(TimeDataUpdated);
				}
			case Rollback(plysToUndo, timeData):
				model.history.dropLast(plysToUndo);

				var newMoveCount:Int = model.getLineLength();

				if (model.shownMovePointer > newMoveCount || Preferences.autoScrollOnMove.get().match(Always | OwnGameOnly))
				{
					model.shownMovePointer = newMoveCount;
					modelUpdateHandler(ViewedMoveNumUpdated);
				}
				
				if (timeData != null)
				{
					model.perMoveTimeRemaindersData.rollback(newMoveCount);
					model.perMoveTimeRemaindersData.modifyLast(timeData);
					model.activeTimerColor = newMoveCount < 2? null : newMoveCount % 2 == 0? White : Black;
					modelUpdateHandler(TimeDataUpdated);
				}
				
				modelUpdateHandler(HistoryRollback);
			case TimeAdded(receiver, timeData):
				model.perMoveTimeRemaindersData.modifyLast(timeData);
				modelUpdateHandler(TimeDataUpdated);

				model.chatHistory.push(Log(TIME_ADDED_MESSAGE(receiver)));
				modelUpdateHandler(EntryAddedToChatHistory);
			case GameEnded(outcome, timeData, rematchPossible, newPersonalElo):

			case PlayerDisconnected(color):
				if (color != model.getPlayerColor())
				{
					model.opponentOnline = false;
					modelUpdateHandler(PlayerOnlineStatusUpdated);
				}
			case PlayerReconnected(color):
				if (color != model.getPlayerColor())
				{
					model.opponentOnline = true;
					modelUpdateHandler(PlayerOnlineStatusUpdated);
				}
			case NewSpectator(ref):
				model.spectatorRefs.push(ref);
				modelUpdateHandler(SpectatorListUpdated);
			case SpectatorLeft(ref):
				model.spectatorRefs.remove(ref);
				modelUpdateHandler(SpectatorListUpdated);
			case OfferActionPerformed(offerSentBy, offer, action):
				var direction:OfferDirection = offerSentBy == model.getPlayerColor()? Outgoing : Incoming;
				var active:Bool = action.match(Create);
				model.offerActive[offer][direction] = active;
				modelUpdateHandler(OfferStateUpdated(offer, direction, active));

				model.chatHistory.push(Log(OFFER_ACTION_MESSAGE(offer, offerSentBy, action)));
				modelUpdateHandler(EntryAddedToChatHistory);
			default:
		}
	}

	public function onEntered(modelUpdateHandler:ModelUpdateEvent->Void, screenRef:IGameScreen)
	{
		this.modelUpdateHandler = modelUpdateHandler;
		this.screenRef = screenRef;

		if (!Lambda.empty(model.plannedPremoves))
		{
			model.plannedPremoves = [];
			modelUpdateHandler(PlannedPremovesUpdated);
		}

		model.deriveInteractivityModeFromOtherParams();
		modelUpdateHandler(InteractivityModeUpdated);
	}

	public function handleGameboardEvent(event:GameboardEvent)
	{
		//* Do nothing
	}

	public function handleChatboxEvent(event:ChatboxEvent)
	{
		switch event 
		{
			case MessageSent(text):
				Networker.emitEvent(Message(text));

				model.chatHistory.push(PlayerMessage(LoginManager.getRef(), text));
				modelUpdateHandler(EntryAddedToChatHistory);
		}
	}

	private function onOfferActionRequested(kind:OfferKind, action:OfferAction)
	{
		var playerColor:PieceColor = model.getPlayerColor();

		var active:Bool = action.match(Create);
		var direction:OfferDirection = action.match(Create | Cancel)? Outgoing : Incoming;
		var offerSentBy:PieceColor = direction.match(Outgoing)? playerColor : opposite(playerColor);

		Networker.emitEvent(PerformOfferAction(kind, action));

		model.offerActive[kind][direction] = active;
		modelUpdateHandler(OfferStateUpdated(kind, direction, active));

		model.chatHistory.push(Log(OFFER_ACTION_MESSAGE(kind, offerSentBy, action)));
		modelUpdateHandler(EntryAddedToChatHistory);
	}

	public function handleActionBarEvent(event:ActionBarEvent)
	{
		switch event 
		{
			case ActionButtonPressed(btn):
				onActionButtonPressed(btn);
			case IncomingOfferAccepted(kind):
				onOfferActionRequested(kind, Accept);
			case IncomingOfferDeclined(kind):
				onOfferActionRequested(kind, Decline);
		}
	}

	private function onActionButtonPressed(btn:ActionButton)
	{
		switch btn.unwrap() 
		{
			case Resign | Abort:
				Networker.emitEvent(Resign);
			case ChangeOrientation:
				model.orientation = opposite(model.orientation);
				modelUpdateHandler(OrientationUpdated);
			case OfferDraw:
				onOfferActionRequested(Draw, Create);
			case CancelDraw:
				onOfferActionRequested(Draw, Cancel);
			case OfferTakeback:
				onOfferActionRequested(Takeback, Create);
			case CancelTakeback:
				onOfferActionRequested(Takeback, Cancel);
			case AddTime:
				Networker.emitEvent(AddTime);
			case Rematch:
				Networker.emitEvent(SimpleRematch);
			case Share:
				var gameLink:String = Url.getGameLink(model.gameID);
                var playedMoves:Array<RawPly> = model.getLine().map(x -> x.ply);
                var pin:String = PortableIntellectorNotation.serialize(model.getStartingSituation(), playedMoves, model.getPlayerRef(White), model.getPlayerRef(Black), model.getTimeControl(), model.getStartTimestamp(), model.getOutcome());

                var shareDialog:ShareDialog = new ShareDialog();
                shareDialog.initInGame(model.getShownSituation(), model.getOrientation(), gameLink, pin, model.getStartingSituation(), playedMoves);
                shareDialog.showShareDialog();
			case PrevMove:
				if (model.shownMovePointer > 0)
				{
					model.shownMovePointer--;
					modelUpdateHandler(ViewedMoveNumUpdated);
				}
			case NextMove:
				var moveCount:Int = model.getLineLength();
				if (model.shownMovePointer < moveCount)
				{
					model.shownMovePointer++;
					modelUpdateHandler(ViewedMoveNumUpdated);
				}
			case OpenChat:
				screenRef.displaySubscreen(Chat);
			case OpenBranching:
				screenRef.displaySubscreen(Branching);
			case OpenSpecialControlSettings:
				screenRef.displaySubscreen(SpecialControlSettings);
			case OpenGameInfo:
				screenRef.displaySubscreen(GameInfoSubscreen);
			default:
		}
	}

	public function handlePlyHistoryViewEvent(event:PlyHistoryViewEvent)
	{
		switch event 
		{
			case ScrollRequested(Home):
				if (model.shownMovePointer > 0)
				{
					model.shownMovePointer = 0;
					modelUpdateHandler(ViewedMoveNumUpdated);
				}
			case ScrollRequested(Prev):
				if (model.shownMovePointer > 0)
				{
					model.shownMovePointer--;
					modelUpdateHandler(ViewedMoveNumUpdated);
				}
			case ScrollRequested(Next):
				var moveCount:Int = model.getLineLength();
				if (model.shownMovePointer < moveCount)
				{
					model.shownMovePointer++;
					modelUpdateHandler(ViewedMoveNumUpdated);
				}
			case ScrollRequested(End):
				var moveCount:Int = model.getLineLength();
				if (model.shownMovePointer < moveCount)
				{
					model.shownMovePointer = moveCount;
					modelUpdateHandler(ViewedMoveNumUpdated);
				}
			case ScrollRequested(Precise(plyNum)):
				if (model.shownMovePointer != plyNum)
				{
					model.shownMovePointer = plyNum;
					modelUpdateHandler(ViewedMoveNumUpdated);
				}
		}
	}

	public function handleVariationViewEvent(event:VariationViewEvent)
	{
		//* Do nothing (this component doesn't occur in real game)
	}

	public function handlePositionEditorEvent(event:PositionEditorEvent)
	{
		//* Do nothing (this component doesn't occur in real game)
	}

	public function handleGlobalEvent(event:GlobalEvent) 
	{
		switch event 
		{
			case PreferenceUpdated(Premoves):
				//TODO: Change behaviour
			default:
		}
	}

    public function new(model:MatchVersusPlayerModel)
	{
		this.model = model;
	}
}