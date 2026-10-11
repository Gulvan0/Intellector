package client.datatypes.game;

import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;
import morestd.Signal;

typedef ActiveOffer =
{
    kind:OfferKind,
    author:PieceColor
}

/**
    What changes as a game goes: its plies (and which one is shown), the clocks after each of them,
    the chat, the active offers and the ending. Fed the server's numbered events; an event already
    applied is skipped, so overlapping sources (a full load, then live events) are safe.
**/
class LiveGameState
{
    public final info:LiveGameInfo;
    /** The plies; reports the shown position's changes itself **/
    public final history:PlyHistory;
    /** Dispatched on every change but the plies' **/
    public final onChanged:Signal<LiveGameChange> = new Signal();

    // clocksAfterPly[k]: both clocks right after k plies; [0] is the initial one
    private var clocksAfterPly:Array<Null<GameClock>>;
    private var latestClock:Null<GameClock>;
    private var chat:Array<GameChatMessage> = [];
    private var offers:Array<ActiveOffer> = [];
    private var ending:Null<GameEnding> = null;
    private var lastEventIndex:Int = -1;

    /** `latestClock`: as of the last event, if newer than the last ply's **/
    public function new(info:LiveGameInfo, events:Array<LiveGameEvent>, latestClock:Null<GameClock>, ending:Null<GameEnding>)
    {
        this.info = info;
        history = new PlyHistory(info.startingPosition);
        clocksAfterPly = [info.initialClock()];
        this.latestClock = info.initialClock();

        for (event in events)
            apply(event, true);

        if (latestClock != null)
            this.latestClock = latestClock;
        this.ending = ending;
        if (ending != null)
            offers = [];
    }

    public function isOver():Bool
    {
        return ending != null;
    }

    public function getEnding():Null<GameEnding>
    {
        return ending;
    }

    public function getChat():Array<GameChatMessage>
    {
        return chat.copy();
    }

    public function hasOffer(kind:OfferKind, author:PieceColor):Bool
    {
        return Lambda.exists(offers, offer -> offer.kind == kind && offer.author == author);
    }

    /**
        Both clocks right after `plyCount` plies, stopped. At the latest ply: running while the game
        goes on, as they were at the end once it's over. Null for a correspondence game.
    **/
    public function clockAt(plyCount:Int):Null<GameClock>
    {
        if (plyCount < history.plyCount())
            return clocksAfterPly[plyCount]?.stopped();

        var clock:Null<GameClock> = ending != null ? ending.finalClock ?? latestClock : latestClock;
        return ending != null ? clock?.stopped() : clock;
    }

    /**
        Applies a server event, unless applied already. `followLatestMove`: whether a new ply brings
        the view back from an older position. Returns false if the event can't be placed (a ply
        beyond the next one): the state is then missing events and needs `resync`.
    **/
    public function apply(event:LiveGameEvent, followLatestMove:Bool):Bool
    {
        var eventIndex:Int = eventIndexOf(event);
        if (eventIndex <= lastEventIndex)
            return true;

        switch event
        {
            case Ply(_, plyIndex, ply, clock):
                if (plyIndex > history.plyCount())
                    return false;
                applyPly(plyIndex, ply, clock, followLatestMove);
            case ChatMessage(_, message):
                chat.push(message);
                onChanged.dispatch(Chat(message));
            case Offer(_, action, kind, author):
                offers = offers.filter(offer -> offer.kind != kind || offer.author != author);
                if (action == Create)
                    offers.push({kind: kind, author: author});
                onChanged.dispatch(Offers);
            case TimeAdded(_, _, clock):
                latestClock = clock;
                onChanged.dispatch(Clock);
            case Rollback(_, plyCountAfter, clock):
                history.truncate(plyCountAfter);
                clocksAfterPly.splice(plyCountAfter + 1, clocksAfterPly.length);
                latestClock = clock ?? clocksAfterPly[clocksAfterPly.length - 1];
                onChanged.dispatch(Clock);
        }

        lastEventIndex = eventIndex;
        return true;
    }

    /** The user's own ply, shown before the server confirms it; the clocks are estimated meanwhile **/
    public function playOwn(ply:RawPly, nowMs:Float):Void
    {
        var mover:PieceColor = history.latestPosition().turnColor;
        var newPlyIndex:Int = history.plyCount();
        history.append(ply, true);

        var clock:Null<GameClock> = latestClock?.afterPly(mover, nowMs, incrementMs(), newPlyIndex >= 1);
        clocksAfterPly.push(clock);
        latestClock = clock;
        onChanged.dispatch(Clock);
    }

    public function end(ending:GameEnding):Void
    {
        this.ending = ending;
        offers = [];
        onChanged.dispatch(Offers);
        onChanged.dispatch(Ended);
    }

    /** Replaces everything with a full snapshot, keeping the shown position where the plies agree **/
    public function resync(events:Array<LiveGameEvent>, latestClock:Null<GameClock>, ending:Null<GameEnding>, followLatestMove:Bool):Void
    {
        var snapshot:LiveGameState = new LiveGameState(info, events, latestClock, ending);

        var commonPlyCount:Int = 0;
        var maxCommon:Int = Std.int(Math.min(history.plyCount(), snapshot.history.plyCount()));
        while (commonPlyCount < maxCommon && history.plyAt(commonPlyCount).equals(snapshot.history.plyAt(commonPlyCount)))
            commonPlyCount++;

        history.truncate(commonPlyCount);
        for (i in commonPlyCount...snapshot.history.plyCount())
            history.append(snapshot.history.plyAt(i), followLatestMove);

        clocksAfterPly = snapshot.clocksAfterPly;
        this.latestClock = snapshot.latestClock;
        chat = snapshot.chat;
        offers = snapshot.offers;
        lastEventIndex = snapshot.lastEventIndex;
        var wasOver:Bool = this.ending != null;
        this.ending = snapshot.ending;

        onChanged.dispatch(Chat(null));
        onChanged.dispatch(Offers);
        onChanged.dispatch(Clock);
        if (!wasOver && this.ending != null)
            onChanged.dispatch(Ended);
    }

    // a ply the history has already (the user's own, echoed back) only brings its clocks
    private function applyPly(plyIndex:Int, ply:RawPly, clock:Null<GameClock>, followLatestMove:Bool):Void
    {
        var known:Bool = plyIndex < history.plyCount() && history.plyAt(plyIndex).equals(ply);
        if (!known)
        {
            history.truncate(plyIndex);
            clocksAfterPly.splice(plyIndex + 1, clocksAfterPly.length);
            history.append(ply, followLatestMove);
        }

        clocksAfterPly[plyIndex + 1] = clock ?? clocksAfterPly[plyIndex];
        if (plyIndex + 1 == history.plyCount())
            latestClock = clocksAfterPly[plyIndex + 1];
        onChanged.dispatch(Clock);
    }

    private function incrementMs():Int
    {
        return switch info.timeControl {
            case None: 0;
            case Fischer(instance): instance.incrementSeconds * 1000;
        }
    }

    private static function eventIndexOf(event:LiveGameEvent):Int
    {
        return switch event {
            case Ply(eventIndex, _, _, _): eventIndex;
            case ChatMessage(eventIndex, _): eventIndex;
            case Offer(eventIndex, _, _, _): eventIndex;
            case TimeAdded(eventIndex, _, _): eventIndex;
            case Rollback(eventIndex, _, _): eventIndex;
        }
    }
}
