package client.ui.game.controllers;

import client.datatypes.game.GameClock;
import client.datatypes.game.GameEnding;
import client.datatypes.game.LiveGameEvent;
import client.datatypes.request.FailedAction;
import client.ui.common.notifications.RequestFailureNotice;
import client.utils.TimedLoad;
import easypubsub.Subscription;
import http.HttpError;
import net.models.game.GamePublic;
import net.models.game.GameStateRefresh;
import net.models.game.mappers.GameClockMapper;
import net.models.game.mappers.LiveGameMapper;
import net.rest.Rest;
import net.rest.RestOperationRegistry;
import net.ws.PubSub;
import net.ws.channels.Game as GameChannel;
import net.ws.events.GameEnded as GameEndedEvent;
import net.ws.events.GameRefresh as GameRefreshEvent;
import net.ws.events.GameSuspensionChanged as GameSuspensionChangedEvent;
import net.ws.events.NewChatMessage as NewChatMessageEvent;
import net.ws.events.NewPly as NewPlyEvent;
import net.ws.events.OfferActionPerformed as OfferActionPerformedEvent;
import net.ws.events.Rollback as RollbackEvent;
import net.ws.events.TimeAdded as TimeAddedEvent;

typedef GameFeedHandlers =
{
    /** The first load has begun, or begun anew after a failure **/
    onFirstLoadStarted:Void->Void,
    /** Followed by the live events that came meanwhile, then by `onCaughtUp` **/
    onFirstLoaded:GamePublic->Void,
    onCaughtUp:Void->Void,
    /** Gets the locale key of what went wrong; `GameFeed.load` retries **/
    onFirstLoadFailed:String->Void,
    onNotFound:Void->Void,
    /** A full snapshot: its events, the clock and the ending **/
    onSnapshot:Array<LiveGameEvent>->Null<GameClock>->Null<GameEnding>->Void,
    onEvent:LiveGameEvent->Void,
    onEnded:GameEnding->Void
}

/**
    Delivers a game from the server: loads it, then follows it over its channel, holding back the
    live events until the first load is through. A later failure to load is a notice with a retry.
**/
class GameFeed
{
    /** The game's channel, which others may follow too **/
    public final channel:GameChannel;

    private final gameId:Int;
    private final handlers:GameFeedHandlers;
    private final subscription:Subscription<GameChannel>;

    private final timedLoad:TimedLoad = new TimedLoad();

    private var loaded:Bool = false;
    private var pendingEvents:Array<Void->Void> = [];

    public function new(gameId:Int, handlers:GameFeedHandlers)
    {
        this.gameId = gameId;
        this.handlers = handlers;

        channel = new GameChannel(gameId);
        subscription = PubSub.sub(channel)
            .onEventLight(GameRefreshEvent, refresh -> whenLoaded(() -> onRefresh(refresh)))
            .onEventLight(NewPlyEvent, ply -> whenLoaded(() -> handlers.onEvent(LiveGameMapper.plyToDatatype(ply))))
            .onEventLight(NewChatMessageEvent, message -> whenLoaded(() -> handlers.onEvent(LiveGameMapper.chatMessageToDatatype(message))))
            .onEventLight(OfferActionPerformedEvent, offer -> whenLoaded(() -> handlers.onEvent(LiveGameMapper.offerToDatatype(offer))))
            .onEventLight(TimeAddedEvent, timeAdded -> whenLoaded(() -> handlers.onEvent(LiveGameMapper.timeAddedToDatatype(timeAdded))))
            .onEventLight(RollbackEvent, rollback -> whenLoaded(() -> handlers.onEvent(LiveGameMapper.rollbackToDatatype(rollback))))
            .onEventLight(GameSuspensionChangedEvent, suspension -> whenLoaded(() -> handlers.onEvent(LiveGameMapper.suspensionToDatatype(suspension))))
            .onEventLight(GameEndedEvent, ended -> whenLoaded(() -> handlers.onEnded(LiveGameMapper.endedToDatatype(ended))));
    }

    public function load():Void
    {
        if (!loaded)
            handlers.onFirstLoadStarted();

        timedLoad.start(
            (onLoaded, onFailed) -> Rest.client().execute(RestOperationRegistry.GET_GAME, onLoaded, onFailed, ["game_id" => Std.string(gameId)]),
            onGameReceived,
            onLoadFailed
        );
    }

    public function dispose():Void
    {
        timedLoad.cancel();
        RequestFailureNotice.dismissAll(SYNC_GAME);
        subscription.detach();
    }

    /** `error` is null for a timeout **/
    private function onLoadFailed(error:Null<HttpError>):Void
    {
        if (error == null)
        {
            if (loaded)
                RequestFailureNotice.show(SYNC_GAME, NoConnection, load);
            else
                handlers.onFirstLoadFailed("intellector.live_game.status.timeout");
        }
        else if (loaded)
            RequestFailureNotice.showHttpError(SYNC_GAME, error, load); // the board stays shown, so the failure is a notice rather than the status screen
        else if (error.httpStatus == 404)
            handlers.onNotFound();
        else
            handlers.onFirstLoadFailed("intellector.live_game.status.failed");
    }

    private function onGameReceived(game:GamePublic):Void
    {
        RequestFailureNotice.dismissAll(SYNC_GAME);

        if (loaded)
        {
            handlers.onSnapshot(LiveGameMapper.eventsToDatatype(game.events), GameClockMapper.dtoToDatatype(game.latest_time_update), LiveGameMapper.outcomeToDatatype(game.outcome));
            return;
        }

        loaded = true;
        handlers.onFirstLoaded(game);

        for (applyPending in pendingEvents)
            applyPending();
        pendingEvents = [];
        handlers.onCaughtUp();
    }

    private function whenLoaded(apply:Void->Void):Void
    {
        if (loaded)
            apply();
        else
            pendingEvents.push(apply);
    }

    private function onRefresh(refresh:GameStateRefresh):Void
    {
        handlers.onSnapshot(LiveGameMapper.eventsToDatatype(refresh.events), GameClockMapper.dtoToDatatype(refresh.latest_time_update), LiveGameMapper.outcomeToDatatype(refresh.outcome));
    }
}
