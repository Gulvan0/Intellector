package client.ui.game.controllers;

import client.datatypes.game.LiveGameState;
import client.datatypes.game.OfferAction;
import client.datatypes.game.OfferKind;
import client.datatypes.request.FailedAction;
import client.ui.common.notifications.RequestFailureNotice;
import client.ui.game.ActionsCard;
import client.ui.game.BoardStage;
import client.ui.game.OfferBar;
import haxefolio.LocaleUtils;
import intellectorboard.primitives.piece.PieceColor;
import net.models.game.mappers.LiveGameMapper;
import net.rest.Rest;
import net.rest.RestOperationRegistry;

/** The draw and takeback offers and the resignation: the bars over the board asking the user, and what the action buttons allow **/
class GameOffersController
{
    private final session:LiveGameSession;
    private final stage:BoardStage;
    private final actionsCard:ActionsCard;

    private var resignAsked:Bool = false;

    public function new(session:LiveGameSession, stage:BoardStage, actionsCard:ActionsCard)
    {
        this.session = session;
        this.stage = stage;
        this.actionsCard = actionsCard;
    }

    public function refresh():Void
    {
        stage.requests.removeAllComponents();

        if (!session.isPlaying())
            return;

        var state:LiveGameState = session.state;
        var userColor:PieceColor = session.userColor;
        var opponentColor:PieceColor = userColor.opposite();
        var opponentNickname:String = state.info.participant(opponentColor).nickname;
        var plyCount:Int = state.history.plyCount();

        if (state.hasOffer(Draw, opponentColor))
            stage.requests.addComponent(createOfferBar("intellector.live_game.request.draw", opponentNickname, Draw));
        if (state.hasOffer(Takeback, opponentColor))
            stage.requests.addComponent(createOfferBar("intellector.live_game.request.takeback", opponentNickname, Takeback));
        if (resignAsked)
            stage.requests.addComponent(createResignBar(plyCount < 2));

        var takebackThreshold:Int = state.info.startingPosition.turnColor == userColor ? 1 : 2; // the user's first move made
        actionsCard.setDrawState(state.hasOffer(Draw, userColor), !state.hasOffer(Draw, opponentColor) && plyCount >= 2);
        if (state.info.bot != null)
            actionsCard.setTakebackState(false, plyCount >= takebackThreshold);
        else
            actionsCard.setTakebackState(state.hasOffer(Takeback, userColor), !state.hasOffer(Takeback, opponentColor) && plyCount >= takebackThreshold);
        actionsCard.setResignIsAbort(plyCount < 2);
    }

    /** Makes the user's offer of `kind`, or takes it back if it's standing **/
    public function toggle(kind:OfferKind):Void
    {
        perform(session.state.hasOffer(kind, session.userColor) ? Cancel : Create, kind);
    }

    public function askResign():Void
    {
        resignAsked = true;
        refresh();
    }

    /** The game has ended: there's nothing to resign anymore **/
    public function onEnded():Void
    {
        resignAsked = false;
    }

    private function createOfferBar(textKey:String, opponentNickname:String, kind:OfferKind):OfferBar
    {
        var bar:OfferBar = new OfferBar();
        bar.setText(LocaleUtils.resolveText(LocaleUtils.localeBinding(textKey), LocaleUtils.resolveText(opponentNickname)));
        bar.addAnswer(LocaleUtils.localeBinding("intellector.live_game.request.decline"), false, () -> perform(Decline, kind));
        bar.addAnswer(LocaleUtils.localeBinding("intellector.live_game.request.accept"), true, () -> perform(Accept, kind));
        return bar;
    }

    private function createResignBar(abort:Bool):OfferBar
    {
        var bar:OfferBar = new OfferBar();
        bar.setText(LocaleUtils.localeBinding(abort ? "intellector.live_game.request.abort_confirm" : "intellector.live_game.request.resign_confirm"));
        bar.addAnswer(LocaleUtils.localeBinding("intellector.live_game.request.cancel"), false, () -> {
            resignAsked = false;
            refresh();
        });
        bar.addAnswer(LocaleUtils.localeBinding(abort ? "intellector.live_game.action.abort" : "intellector.live_game.action.resign"), true, resign);
        return bar;
    }

    private function resign():Void
    {
        resignAsked = false;
        refresh();
        session.commands().resign(session.state.history.plyCount() < 2, RequestFailureNotice.showHttpError.bind(RESIGN));
    }

    private function perform(action:OfferAction, kind:OfferKind):Void
    {
        var failedAction:FailedAction = switch [action, kind] {
            case [Create, Draw]: OFFER_DRAW;
            case [Cancel, Draw]: CANCEL_DRAW;
            case [_, Draw]: ANSWER_DRAW;
            case [Create, Takeback]: OFFER_TAKEBACK;
            case [Cancel, Takeback]: CANCEL_TAKEBACK;
            case [_, Takeback]: ANSWER_TAKEBACK;
        }
        Rest.client().execute(
            RestOperationRegistry.PERFORM_OFFER_ACTION_IN_INTERNAL_GAME,
            _ -> {},
            RequestFailureNotice.showHttpError.bind(failedAction),
            null,
            null,
            LiveGameMapper.offerActionToDto(session.gameId, action, kind)
        );
    }
}
