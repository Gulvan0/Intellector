package client.ui.challenge;

import client.auth.Identity;
import client.auth.IdentityKeeper;
import client.datatypes.challenge.ChallengeDetails;
import client.datatypes.challenge.ChallengeStatus;
import client.datatypes.request.FailedAction;
import client.logic.challenge.ChallengeViewers;
import client.ui.common.LoadStatus;
import client.ui.common.WidthObserver;
import client.ui.common.notifications.InfoNotice;
import client.ui.common.notifications.RequestFailureNotice;
import client.ui.common.overlays.login.LoginOverlay;
import client.utils.PagePaths;
import client.utils.TimedLoad;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.core.Component;
import haxe.ui.containers.VBox;
import haxefolio.ByMenuLayout;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;
import haxefolio.PageLink;
import haxefolio.ResponsivityController;
import http.HttpError;
import easypubsub.Subscription;
import morestd.Detachable;
import net.models.challenge.mappers.ChallengeDetailsMapper;
import net.rest.Rest;
import net.rest.RestOperationRegistry;
import net.ws.PubSub;
import net.ws.channels.PublicChallengeList;
import net.ws.events.PublicChallengeCancelled;
import net.ws.events.PublicChallengeFulfilled;
import net.ws.events.PublicChallengesCancelledByServer;

/**
    A challenge opened by its link: accepted, declined (by its callee) or cancelled by its owner,
    from here. A challenge that's no longer pending forwards the user to its game, or home if it was
    cancelled. While an open challenge is on display, it's followed over the public challenge list
    channel: once it's resolved elsewhere, the page reloads it.
**/
class ChallengeJoiningPage extends PageBase
{
    private static inline final CARD_MAX_WIDTH:Float = 420;
    private static inline final CANCELLED_NOTICE_MS:Int = 6000;
    private static final GUTTER:ByMenuLayout<Int> = {expanded: 22, collapsed: 14};

    private final challengeId:Int;
    private final load:TimedLoad = new TimedLoad();
    private final handles:Array<Detachable> = [];

    private var frame:Null<VBox> = null;
    private var content:Null<Component> = null;
    private var contentIsCard:Bool = false;
    private var card:Null<ChallengeJoiningCard> = null;
    private var challenge:Null<ChallengeDetails> = null;
    private var pageWidth:Float = 0;
    private var gutter:Float = 0;
    private var closed:Bool = false;
    private var publicChallengesSubscription:Null<Subscription<PublicChallengeList>> = null;

    public function new(challengeId:Int)
    {
        super();
        this.challengeId = challengeId;
    }

    private override function init():Void
    {
        setTitle(LocaleUtils.localeBinding("intellector.challenge_joining.title"), challengeId);

        frame = new VBox();
        frame.percentWidth = 100;
        frame.addClass(StyleClass.JOIN_FRAME);
        addComponent(frame);

        handles.push(WidthObserver.observe(this, width -> {
            pageWidth = width;
            fitContent();
        }));
        handles.push(ResponsivityController.bind(GUTTER, value -> {
            gutter = value;
            fitContent();
        }));
        IdentityKeeper.addChangeListener(onIdentityChanged);

        loadChallenge();
    }

    private override function onClose():Void
    {
        closed = true;
        load.cancel();
        unfollow();
        IdentityKeeper.removeChangeListener(onIdentityChanged);
        for (handle in handles)
            handle.detach();
    }

    private function loadChallenge():Void
    {
        if (card == null)
            showLoadStatus().showLoading();

        load.start(
            (onResponse, onError) -> Rest.client().execute(RestOperationRegistry.GET_CHALLENGE, onResponse, onError, ["challenge_id" => Std.string(challengeId)]),
            dto -> onLoaded(ChallengeDetailsMapper.dtoToStatus(dto)),
            onLoadFailed
        );
    }

    private function onLoaded(status:ChallengeStatus):Void
    {
        switch status
        {
            case Pending(pending):
                showCard(pending);
            case Accepted(gameId):
                HaxeFolioApp.redirectTo(PagePaths.liveGame(gameId));
            case Cancelled:
                redirectHomeAsCancelled();
        }
    }

    private function onLoadFailed(error:Null<HttpError>):Void
    {
        if (error != null && error.httpStatus == 404)
            showNotFound();
        else
            showLoadStatus().showFailure(error == null, loadChallenge);
    }

    private function showCard(pending:ChallengeDetails):Void
    {
        challenge = pending;
        card = new ChallengeJoiningCard(pending, acceptChallenge, declineChallenge, cancelChallenge);
        card.setViewer(ChallengeViewers.of(pending, IdentityKeeper.currentIdentity.getUserRef()));
        setContent(card, true);

        if (!pending.isDirect())
            follow();
    }

    // a direct challenge isn't on the public list: its sides learn of its fate through their own notifications
    private function follow():Void
    {
        if (publicChallengesSubscription != null)
            return;

        publicChallengesSubscription = PubSub.sub(new PublicChallengeList())
            .onEventLight(PublicChallengeCancelled, id -> reloadIfResolved([id.id]))
            .onEventLight(PublicChallengeFulfilled, id -> reloadIfResolved([id.id]))
            .onEventLight(PublicChallengesCancelledByServer, idList -> reloadIfResolved(idList.ids));
    }

    private function unfollow():Void
    {
        if (publicChallengesSubscription != null)
            publicChallengesSubscription.detach();
        publicChallengesSubscription = null;
    }

    // the owner is taken to the started game by the global handling, and has just cancelled it themselves otherwise
    private function reloadIfResolved(resolvedIds:Array<Int>):Void
    {
        if (closed || card == null || !resolvedIds.contains(challengeId) || ChallengeViewers.of(challenge, IdentityKeeper.currentIdentity.getUserRef()) == Owner)
            return;

        unfollow();
        loadChallenge();
    }

    private function showLoadStatus():LoadStatus
    {
        unfollow();
        card = null;
        challenge = null;

        var status:LoadStatus = new LoadStatus();
        var statusCard:VBox = new VBox();
        statusCard.addClass(StyleClass.JOIN_CARD);
        statusCard.addClass(StyleClass.JOIN_STATUS_CARD);
        statusCard.addComponent(status);
        setContent(statusCard, true);
        return status;
    }

    // nothing to retry: the user goes looking for another challenge
    private function showNotFound():Void
    {
        unfollow();
        card = null;
        challenge = null;

        var statusBox:VBox = new VBox();
        statusBox.addClass(StyleClass.GAME_STATUS);

        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding("intellector.challenge_joining.not_found", Std.string(challengeId));
        label.horizontalAlign = "center";
        label.addClass(StyleClass.GAME_STATUS_TEXT);
        statusBox.addComponent(label);

        var hintLabel:Label = new Label();
        hintLabel.text = LocaleUtils.localeBinding("intellector.challenge_joining.not_found_hint");
        hintLabel.horizontalAlign = "center";
        hintLabel.addClass(StyleClass.GAME_STATUS_HINT);
        statusBox.addComponent(hintLabel);

        var actionButton:Button = new Button();
        actionButton.text = LocaleUtils.localeBinding("intellector.live_game.status.to_main_page");
        actionButton.horizontalAlign = "center";
        actionButton.addClass(StyleClass.GAME_BUTTON);
        actionButton.addClass(StyleClass.GAME_BUTTON_PRIMARY);
        PageLink.attach(actionButton, HaxeFolioApp.defaultPagePath);
        statusBox.addComponent(actionButton);

        setContent(statusBox, false);
    }

    /** `isCard`: as wide as a card may be, rather than its own width **/
    private function setContent(component:Component, isCard:Bool):Void
    {
        if (content != null)
            frame.removeComponent(content, true);

        content = component;
        contentIsCard = isCard;
        content.horizontalAlign = "center";
        frame.addComponent(content);
        fitContent();
    }

    private function fitContent():Void
    {
        if (content == null || !contentIsCard || pageWidth <= 0)
            return;

        content.width = Math.min(CARD_MAX_WIDTH, pageWidth - 2 * gutter);
    }

    private function onIdentityChanged(identity:Identity):Void
    {
        if (card != null)
            card.setViewer(ChallengeViewers.of(challenge, identity.getUserRef()));
    }

    private function acceptChallenge():Void
    {
        if (challenge.rated && IdentityKeeper.currentIdentity.isGuest())
        {
            LoginOverlay.present();
            return;
        }

        card.setBusy(true);
        Rest.client().execute(
            RestOperationRegistry.ACCEPT_CHALLENGE,
            game -> {
                if (closed)
                    HaxeFolioApp.navigateTo(PagePaths.liveGame(game.id));
                else
                    HaxeFolioApp.redirectTo(PagePaths.liveGame(game.id));
            },
            onActionFailed.bind(ACCEPT_CHALLENGE),
            ["challenge_id" => Std.string(challengeId)]
        );
    }

    private function declineChallenge():Void
    {
        card.setBusy(true);
        Rest.client().execute(
            RestOperationRegistry.DECLINE_CHALLENGE,
            _ -> {
                if (!closed)
                    HaxeFolioApp.redirectTo(HaxeFolioApp.defaultPagePath);
            },
            onActionFailed.bind(DECLINE_CHALLENGE),
            ["challenge_id" => Std.string(challengeId)]
        );
    }

    private function cancelChallenge():Void
    {
        card.setBusy(true);
        Rest.client().execute(
            RestOperationRegistry.CANCEL_CHALLENGE,
            _ -> {
                if (!closed)
                    redirectHomeAsCancelled();
            },
            onActionFailed.bind(CANCEL_CHALLENGE),
            ["challenge_id" => Std.string(challengeId)]
        );
    }

    // not found, or no longer active: its reloaded state tells where to go
    private function onActionFailed(action:FailedAction, error:HttpError):Void
    {
        if (closed || card == null)
            return;

        if (error.httpStatus == 404 || error.httpStatus == 422)
        {
            loadChallenge();
            return;
        }

        card.setBusy(false);
        RequestFailureNotice.showHttpError(action, error);
    }

    private function redirectHomeAsCancelled():Void
    {
        HaxeFolioApp.redirectTo(HaxeFolioApp.defaultPagePath);
        InfoNotice.show("intellector.challenge_joining.cancelled_notice.title", "intellector.challenge_joining.cancelled_notice.text", CANCELLED_NOTICE_MS);
    }
}
