package client.datatypes.game;

import intellectorboard.mappers.Sip;
import intellectorboard.plyapplication.PlyPerformer;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;
import morestd.Signal;

typedef ActiveOffer =
{
    kind:OfferKind,
    author:PieceColor
}

private typedef PlacedChatEntry =
{
    entry:GameChatEntry,
    // the entries are kept ordered by this: their event's index
    position:Float
}

/**
    What changes as a game goes: its plies (and which one is shown), the clocks after each of them,
    the chat, the active offers and the ending. Takes the server's numbered events in any order and
    any number of times, each applied once:
    - a ply must fit the agreed position, and loses to a rollback numbered after it;
    - the latest rollback wins, keeping the plies numbered after it;
    - the clock and each offer (by its kind and author) take the value of their latest event;
    - the ending is final, except that a late ply still enters the history.
**/
class LiveGameState
{
    /** How long the side to move has for each of the first two plies before the server aborts the game **/
    private static inline final FIRST_MOVE_DEADLINE_SECONDS:Int = 30;
    /** The same for an external game **/
    private static inline final EXTERNAL_FIRST_MOVE_DEADLINE_SECONDS:Int = 300;
    /** Stands for the event of a ply the server hasn't confirmed yet **/
    private static inline final UNCONFIRMED_EVENT_INDEX:Int = -1;

    public final info:LiveGameInfo;
    /** The plies; reports the shown position's changes itself **/
    public final history:PlyHistory;
    /** Dispatched on every change but the plies' **/
    public final onChanged:Signal<LiveGameChange> = new Signal();

    // clocksAfterPly[k]: both clocks right after k plies; [0] is the initial one
    private var clocksAfterPly:Array<Null<GameClock>>;
    // plyTimesMs[k]: when ply k was made
    private var plyTimesMs:Array<Null<Float>> = [];
    // plyEventIndices[k]: the event of ply k
    private var plyEventIndices:Array<Int> = [];
    private var latestClock:Null<GameClock>;
    private var latestClockEventIndex:Int = -1;
    // when the first-move deadline began: the game start, the latest ply or rollback; added time doesn't restart it
    private var deadlineStartMs:Null<Float>;
    private var chat:Array<PlacedChatEntry> = [];
    private var offers:Array<ActiveOffer> = [];
    private var latestOfferEventIndices:Map<String, Int> = [];
    private var ending:Null<GameEnding> = null;
    private var seenEventIndices:Map<Int, Bool> = [];
    private var latestEventIndex:Int = -1;
    private var latestRollbackEventIndex:Int = -1;
    // what `apply` was given: a snapshot received later may lack it
    private final liveEvents:Array<LiveGameEvent> = [];

    /** `latestClock`: as of the last event, if newer than the last ply's **/
    public function new(info:LiveGameInfo, events:Array<LiveGameEvent>, latestClock:Null<GameClock>, ending:Null<GameEnding>)
    {
        this.info = info;
        history = new PlyHistory(info.startingPosition);
        clocksAfterPly = [info.initialClock()];
        this.latestClock = info.initialClock();
        deadlineStartMs = info.startedAtMs;

        for (event in events)
            place(event, true);

        if (latestClock != null)
        {
            this.latestClock = latestClock;
            latestClockEventIndex = latestEventIndex;
        }
        if (ending != null)
            finish(ending);
    }

    /** When the latest ply was made; null before any ply, or if the time wasn't recorded **/
    public function lastPlyAtMs():Null<Float>
    {
        return history.plyCount() > 0 ? plyTimesMs[history.plyCount() - 1] : null;
    }

    public function isOver():Bool
    {
        return ending != null;
    }

    public function getEnding():Null<GameEnding>
    {
        return ending;
    }

    /** A run of the uploader's goings and returns is a single line, telling the latest of them **/
    public function getChat():Array<GameChatEntry>
    {
        var entries:Array<GameChatEntry> = [];
        for (i in 0...chat.length)
            if (i == chat.length - 1 || !isSuspension(chat[i].entry) || !isSuspension(chat[i + 1].entry))
                entries.push(chat[i].entry);
        return entries;
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
        Unix time, in milliseconds, from which the side to move has `firstMoveDeadlineSeconds()` to play before the
        server aborts the game. Null unless a timed game is going on with fewer than two plies made.
    **/
    public function firstMoveDeadlineSeconds():Int
    {
        return info.isExternal() ? EXTERNAL_FIRST_MOVE_DEADLINE_SECONDS : FIRST_MOVE_DEADLINE_SECONDS;
    }

    public function firstMoveDeadlineStartMs():Null<Float>
    {
        if (isOver() || !info.isTimed() || history.plyCount() >= 2)
            return null;
        return deadlineStartMs;
    }

    /**
        Applies a server event, unless applied already. `followLatestMove`: whether a new ply brings
        the view back from an older position. Returns false if the event doesn't fit the agreed
        position: the state has then diverged and needs `resync`.
    **/
    public function apply(event:LiveGameEvent, followLatestMove:Bool):Bool
    {
        if (seenEventIndices.exists(eventIndexOf(event)))
            return true;

        liveEvents.push(event);
        return place(event, followLatestMove);
    }

    /** The user's own ply, shown before the server confirms it; the clocks are estimated meanwhile **/
    public function playOwn(ply:RawPly, nowMs:Float):Void
    {
        var mover:PieceColor = history.latestPosition().turnColor;
        var newPlyIndex:Int = history.plyCount();
        history.append(ply, true);

        var clock:Null<GameClock> = latestClock?.afterPly(mover, nowMs, incrementMs(), newPlyIndex >= 1);
        clocksAfterPly.push(clock);
        plyTimesMs.push(nowMs);
        plyEventIndices.push(UNCONFIRMED_EVENT_INDEX);
        latestClock = clock;
        deadlineStartMs = nowMs;
        onChanged.dispatch(Clock);
    }

    public function end(ending:GameEnding):Void
    {
        finish(ending);
        onChanged.dispatch(Offers);
        onChanged.dispatch(Ended);
    }

    /**
        Replaces everything with a full snapshot, keeping the shown position where the plies agree.
        The snapshot may be older than what was applied: the events it lacks are applied on top of it.
    **/
    public function resync(events:Array<LiveGameEvent>, latestClock:Null<GameClock>, ending:Null<GameEnding>, followLatestMove:Bool):Void
    {
        var snapshot:LiveGameState = new LiveGameState(info, events, latestClock, ending);
        for (event in liveEvents)
            snapshot.place(event, followLatestMove);
        if (snapshot.ending == null && this.ending != null)
            snapshot.finish(this.ending);

        var commonPlyCount:Int = 0;
        var maxCommon:Int = Std.int(Math.min(history.plyCount(), snapshot.history.plyCount()));
        while (commonPlyCount < maxCommon && history.plyAt(commonPlyCount).equals(snapshot.history.plyAt(commonPlyCount)))
            commonPlyCount++;

        history.truncate(commonPlyCount);
        for (i in commonPlyCount...snapshot.history.plyCount())
            history.append(snapshot.history.plyAt(i), followLatestMove);

        clocksAfterPly = snapshot.clocksAfterPly;
        plyTimesMs = snapshot.plyTimesMs;
        plyEventIndices = snapshot.plyEventIndices;
        this.latestClock = snapshot.latestClock;
        latestClockEventIndex = snapshot.latestClockEventIndex;
        deadlineStartMs = snapshot.deadlineStartMs;
        chat = snapshot.chat;
        offers = snapshot.offers;
        latestOfferEventIndices = snapshot.latestOfferEventIndices;
        seenEventIndices = snapshot.seenEventIndices;
        latestEventIndex = snapshot.latestEventIndex;
        latestRollbackEventIndex = snapshot.latestRollbackEventIndex;
        var wasOver:Bool = this.ending != null;
        this.ending = snapshot.ending;

        onChanged.dispatch(Chat(null));
        onChanged.dispatch(Offers);
        onChanged.dispatch(Clock);
        if (!wasOver && this.ending != null)
            onChanged.dispatch(Ended);
    }

    private function place(event:LiveGameEvent, followLatestMove:Bool):Bool
    {
        var eventIndex:Int = eventIndexOf(event);
        if (seenEventIndices.exists(eventIndex))
            return true;

        switch event
        {
            case Ply(_, plyIndex, ply, clock, occurredAtMs, sipAfter):
                if (!placePly(eventIndex, plyIndex, ply, clock, occurredAtMs, sipAfter, followLatestMove))
                    return false;
            case ChatMessage(_, message):
                placeChatEntry(Message(message), eventIndex);
            case Offer(_, action, kind, author):
                var changesOffers:Bool = updateOffer(eventIndex, action, kind, author);
                placeChatEntry(Offer(action, kind, author), eventIndex);
                if (changesOffers)
                    onChanged.dispatch(Offers);
            case TimeAdded(_, receiver, amountSeconds, clock):
                updateLatestClock(clock, eventIndex);
                placeChatEntry(TimeAdded(receiver, amountSeconds), eventIndex);
                onChanged.dispatch(Clock);
            case Rollback(_, plyCountAfter, clock, sip):
                if (!placeRollback(eventIndex, plyCountAfter, clock, sip))
                    return false;
            case Suspension(_, suspended, clock):
                if (clock != null)
                {
                    updateLatestClock(clock, eventIndex);
                    onChanged.dispatch(Clock);
                }
                placeChatEntry(Suspension(suspended), eventIndex);
        }

        seenEventIndices.set(eventIndex, true);
        if (eventIndex > latestEventIndex)
            latestEventIndex = eventIndex;
        return true;
    }

    // a ply the history has already (the user's own, echoed back) only brings its clocks
    private function placePly(eventIndex:Int, plyIndex:Int, ply:RawPly, clock:Null<GameClock>, occurredAtMs:Null<Float>, sipAfter:Null<String>, followLatestMove:Bool):Bool
    {
        if (eventIndex < latestRollbackEventIndex)
            return true;
        if (plyIndex > history.plyCount())
            return false;
        if (sipAfter != null && !plyLeadsTo(plyIndex, ply, sipAfter))
            return false;

        var known:Bool = plyIndex < history.plyCount() && history.plyAt(plyIndex).equals(ply);
        if (!known)
        {
            dropPliesFrom(plyIndex);
            history.append(ply, followLatestMove);
        }
        plyTimesMs[plyIndex] = occurredAtMs;
        plyEventIndices[plyIndex] = eventIndex;

        clocksAfterPly[plyIndex + 1] = clock ?? clocksAfterPly[plyIndex];
        if (plyIndex + 1 == history.plyCount() && updateLatestClock(clocksAfterPly[plyIndex + 1], eventIndex))
            deadlineStartMs = latestClock?.updatedAtMs;
        onChanged.dispatch(Clock);
        return true;
    }

    private function placeRollback(eventIndex:Int, plyCountAfter:Int, clock:Null<GameClock>, sip:Null<String>):Bool
    {
        if (eventIndex < latestRollbackEventIndex)
            return true;
        if (sip != null && (plyCountAfter > history.plyCount() || !isSipOf(history.positionAt(plyCountAfter), sip)))
            return false;

        latestRollbackEventIndex = eventIndex;

        var keptPlyCount:Int = plyCountAfter;
        while (keptPlyCount < history.plyCount() && plyEventIndices[keptPlyCount] > eventIndex)
            keptPlyCount++; // made on top of this rollback, whose event arrives late
        dropPliesFrom(keptPlyCount);

        var clockUpdated:Bool = keptPlyCount > plyCountAfter
            ? updateLatestClock(clocksAfterPly[keptPlyCount], plyEventIndices[keptPlyCount - 1])
            : updateLatestClock(clock ?? clocksAfterPly[clocksAfterPly.length - 1], eventIndex);
        if (clockUpdated)
            deadlineStartMs = latestClock?.updatedAtMs;
        onChanged.dispatch(Clock);
        return true;
    }

    private function plyLeadsTo(plyIndex:Int, ply:RawPly, sipAfter:String):Bool
    {
        try
        {
            return isSipOf(PlyPerformer.positionAfterRawPly(history.positionAt(plyIndex), ply), sipAfter);
        }
        catch (e)
        {
            return false; // impossible in that position
        }
    }

    private function isSipOf(position:Position, sip:String):Bool
    {
        var positionSip:String = Sip.fromPosition(position);
        return positionSip == sip;
    }

    private function dropPliesFrom(plyIndex:Int):Void
    {
        history.truncate(plyIndex);
        clocksAfterPly.splice(plyIndex + 1, clocksAfterPly.length);
        plyTimesMs.splice(plyIndex, plyTimesMs.length);
        plyEventIndices.splice(plyIndex, plyEventIndices.length);
    }

    private function updateLatestClock(clock:Null<GameClock>, eventIndex:Int):Bool
    {
        if (eventIndex < latestClockEventIndex)
            return false;

        latestClock = clock;
        latestClockEventIndex = eventIndex;
        return true;
    }

    private function updateOffer(eventIndex:Int, action:OfferAction, kind:OfferKind, author:PieceColor):Bool
    {
        var key:String = Std.string(kind) + Std.string(author);
        var latestIndex:Null<Int> = latestOfferEventIndices.get(key);
        if (latestIndex != null && eventIndex < latestIndex)
            return false;

        latestOfferEventIndices.set(key, eventIndex);
        offers = offers.filter(offer -> offer.kind != kind || offer.author != author);
        if (action == Create && ending == null)
            offers.push({kind: kind, author: author});
        return true;
    }

    private function finish(ending:GameEnding):Void
    {
        this.ending = ending;
        offers = [];
        placeChatEntry(Ended(ending.outcome), latestEventIndex + 0.5);
    }

    private function placeChatEntry(entry:GameChatEntry, position:Float):Void
    {
        var index:Int = chat.length;
        while (index > 0 && chat[index - 1].position > position)
            index--;

        chat.insert(index, {entry: entry, position: position});

        var collapsesWithPrevious:Bool = index > 0 && isSuspension(entry) && isSuspension(chat[index - 1].entry);
        onChanged.dispatch(Chat(index == chat.length - 1 && !collapsesWithPrevious ? entry : null));
    }

    private static function isSuspension(entry:GameChatEntry):Bool
    {
        return entry.match(Suspension(_));
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
            case Ply(eventIndex, _, _, _, _, _): eventIndex;
            case ChatMessage(eventIndex, _): eventIndex;
            case Offer(eventIndex, _, _, _): eventIndex;
            case TimeAdded(eventIndex, _, _, _): eventIndex;
            case Rollback(eventIndex, _, _, _): eventIndex;
            case Suspension(eventIndex, _, _): eventIndex;
        }
    }
}
