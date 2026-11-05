package client.datatypes.game;

import client.datatypes.timecontrol.FischerTimeControl;
import intellectorboard.movement.rules.PlyRules;
import intellectorboard.plyapplication.PlyPerformer;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;
import utest.Assert;
import utest.Test;

class LiveGameStateTest extends Test
{
    private static function info():LiveGameInfo
    {
        var white:GameParticipant = new GameParticipant("alice", "Alice", new PlayerRating(1500, false));
        var black:GameParticipant = new GameParticipant("_7", "Guest 7", null);
        return new LiveGameInfo(1, white, black, Fischer(new FischerTimeControl(180, 2)), true, 0, Position.defaultStarting(), false, null, null);
    }

    // the first legal ply of each position along the line
    private static function line(length:Int):Array<RawPly>
    {
        var plies:Array<RawPly> = [];
        var position:Position = Position.defaultStarting();
        for (_ in 0...length)
        {
            var ply:RawPly = PlyRules.possiblePlys(position)[0];
            plies.push(ply);
            position = PlyPerformer.positionAfterRawPly(position, ply);
        }
        return plies;
    }

    private static function clock(whiteMs:Int, blackMs:Int, atMs:Float):GameClock
    {
        return new GameClock(whiteMs, blackMs, null, atMs);
    }

    private function testBuildsHistoryAndSkipsAppliedEvents():Void
    {
        var plies:Array<RawPly> = line(2);
        var state:LiveGameState = new LiveGameState(info(), [Ply(0, 0, plies[0], null, null, null), Ply(1, 1, plies[1], null, null, null)], null, null);

        Assert.equals(2, state.history.plyCount());
        Assert.isTrue(state.apply(Ply(1, 1, plies[1], null, null, null), true));
        Assert.equals(2, state.history.plyCount());
    }

    private function testEchoedOwnPlyIsNotDuplicated():Void
    {
        var plies:Array<RawPly> = line(1);
        var state:LiveGameState = new LiveGameState(info(), [], null, null);

        state.playOwn(plies[0], 1_000);
        state.apply(Ply(0, 0, plies[0].copy(), clock(180_000, 180_000, 1_000), null, null), true);

        Assert.equals(1, state.history.plyCount());
    }

    private function testPlyBeyondTheNextOneNeedsResync():Void
    {
        var plies:Array<RawPly> = line(2);
        var state:LiveGameState = new LiveGameState(info(), [], null, null);

        Assert.isFalse(state.apply(Ply(3, 1, plies[1], null, null, null), true));
        Assert.equals(0, state.history.plyCount());
    }

    private function testRollbackDropsPliesAndTheirClocks():Void
    {
        var plies:Array<RawPly> = line(3);
        var events:Array<LiveGameEvent> = [for (i in 0...3) Ply(i, i, plies[i], clock(100_000 - i, 100_000, i), null, null)];
        var state:LiveGameState = new LiveGameState(info(), events, null, null);

        state.apply(Rollback(3, 1, null, null), true);

        Assert.equals(1, state.history.plyCount());
        Assert.equals(100_000, state.clockAt(1).whiteMs);
    }

    private function testOffersFollowTheirActions():Void
    {
        var state:LiveGameState = new LiveGameState(info(), [Offer(0, Create, Draw, White)], null, null);
        Assert.isTrue(state.hasOffer(Draw, White));
        Assert.isFalse(state.hasOffer(Draw, Black));

        state.apply(Offer(1, Cancel, Draw, White), true);
        Assert.isFalse(state.hasOffer(Draw, White));
    }

    private function testOlderPlyClocksAreStoppedAndTheLatestRuns():Void
    {
        var plies:Array<RawPly> = line(2);
        var running:GameClock = new GameClock(170_000, 175_000, White, 5_000);
        var events:Array<LiveGameEvent> = [Ply(0, 0, plies[0], new GameClock(180_000, 180_000, Black, 1_000), null, null), Ply(1, 1, plies[1], running, null, null)];
        var state:LiveGameState = new LiveGameState(info(), events, null, null);

        Assert.isNull(state.clockAt(1).tickingSide);
        Assert.equals(White, state.clockAt(2).tickingSide);
        Assert.equals(180_000, state.clockAt(0).whiteMs);
    }

    private function testEndedGameShowsTheFinalClockStopped():Void
    {
        var state:LiveGameState = new LiveGameState(info(), [], new GameClock(10_000, 20_000, White, 0), null);
        state.end(new GameEnding(Decisive(Timeout, Black), 10_000, new GameClock(0, 20_000, White, 10_000), -8, 8));

        Assert.isTrue(state.isOver());
        Assert.equals(0, state.clockAt(0).whiteMs);
        Assert.isNull(state.clockAt(0).tickingSide);
    }

    private function testResyncKeepsTheShownPositionWhereThePliesAgree():Void
    {
        var plies:Array<RawPly> = line(3);
        var state:LiveGameState = new LiveGameState(info(), [Ply(0, 0, plies[0], null, null, null), Ply(1, 1, plies[1], null, null, null)], null, null);
        state.history.navigate(Start);

        state.resync([for (i in 0...3) Ply(i, i, plies[i], null, null, null)], null, null, false);

        Assert.equals(3, state.history.plyCount());
        Assert.equals(0, state.history.shownPlyIndex());
    }

    private static function message(text:String):GameChatMessage
    {
        return new GameChatMessage("alice", "Alice", text, false);
    }

    private static function chatTexts(state:LiveGameState):Array<String>
    {
        var texts:Array<String> = [];
        for (entry in state.getChat())
            switch entry
            {
                case Message(chatMessage):
                    texts.push(chatMessage.text);
                default:
            }
        return texts;
    }

    private function testLateChatMessageIsAppliedInItsPlace():Void
    {
        var plies:Array<RawPly> = line(2);
        var state:LiveGameState = new LiveGameState(info(), [Ply(0, 0, plies[0], null, null, null)], null, null);

        state.apply(ChatMessage(3, message("later")), true);
        state.apply(Ply(4, 1, plies[1], null, null, null), true);
        Assert.isTrue(state.apply(ChatMessage(2, message("earlier")), true));

        Assert.same(["earlier", "later"], chatTexts(state));
        Assert.equals(2, state.history.plyCount());
    }

    private function testRepeatedChatMessageIsAppliedOnce():Void
    {
        var state:LiveGameState = new LiveGameState(info(), [], null, null);

        state.apply(ChatMessage(0, message("hello")), true);
        state.apply(ChatMessage(0, message("hello")), true);

        Assert.same(["hello"], chatTexts(state));
    }

    private function testLateOfferEventDoesNotOverrideALaterOne():Void
    {
        var state:LiveGameState = new LiveGameState(info(), [], null, null);

        state.apply(Offer(2, Cancel, Draw, White), true);
        state.apply(Offer(1, Create, Draw, White), true);

        Assert.isFalse(state.hasOffer(Draw, White));
        Assert.equals(2, state.getChat().length); // still told in the chat
    }

    private function testLateOfferOfAnotherKindIsApplied():Void
    {
        var state:LiveGameState = new LiveGameState(info(), [], null, null);

        state.apply(Offer(5, Create, Takeback, White), true);
        state.apply(Offer(4, Create, Draw, White), true);

        Assert.isTrue(state.hasOffer(Takeback, White));
        Assert.isTrue(state.hasOffer(Draw, White));
    }

    private function testLateTimeAddedDoesNotOverrideALaterClock():Void
    {
        var plies:Array<RawPly> = line(1);
        var state:LiveGameState = new LiveGameState(info(), [], null, null);
        var plyClock:GameClock = new GameClock(100_000, 100_000, Black, 2_000);

        state.apply(Ply(2, 0, plies[0], plyClock, null, null), true);
        state.apply(TimeAdded(1, White, 15, new GameClock(115_000, 100_000, null, 1_000)), true);

        Assert.equals(100_000, state.clockAt(1).whiteMs);
        Assert.equals(1, state.getChat().length);
    }

    private function testPlyOutrunningAnotherNeedsResyncWhichKeepsIt():Void
    {
        var plies:Array<RawPly> = line(3);
        var state:LiveGameState = new LiveGameState(info(), [Ply(0, 0, plies[0], null, null, null)], null, null);

        Assert.isFalse(state.apply(Ply(2, 2, plies[2], null, null, null), true));
        state.resync([Ply(0, 0, plies[0], null, null, null), Ply(1, 1, plies[1], null, null, null)], null, null, true);

        Assert.equals(3, state.history.plyCount());
    }

    private function testResyncKeepsLiveEventsTheSnapshotLacks():Void
    {
        var state:LiveGameState = new LiveGameState(info(), [], null, null);

        state.apply(ChatMessage(1, message("live")), true);
        state.apply(Offer(2, Create, Draw, Black), true);
        state.resync([ChatMessage(0, message("snapshot"))], null, null, true);

        Assert.same(["snapshot", "live"], chatTexts(state));
        Assert.isTrue(state.hasOffer(Draw, Black));
    }

    private function testResyncDoesNotRepeatLiveEventsTheSnapshotHas():Void
    {
        var state:LiveGameState = new LiveGameState(info(), [], null, null);

        state.apply(ChatMessage(0, message("both")), true);
        state.resync([ChatMessage(0, message("both"))], null, null, true);

        Assert.same(["both"], chatTexts(state));
    }

    private function testLateRollbackKeepsThePlyMadeOnTopOfIt():Void
    {
        var plies:Array<RawPly> = line(2);
        var replay:RawPly = PlyRules.possiblePlys(PlyPerformer.positionAfterRawPly(Position.defaultStarting(), plies[0]))[1];
        var state:LiveGameState = new LiveGameState(info(), [Ply(0, 0, plies[0], null, null, null), Ply(1, 1, plies[1], null, null, null)], null, null);

        state.apply(Ply(3, 1, replay, null, null, null), true);
        Assert.isTrue(state.apply(Rollback(2, 1, null, null), true));

        Assert.equals(2, state.history.plyCount());
        Assert.isTrue(state.history.plyAt(1).equals(replay));
    }

    private function testLatePlyLosesToARollbackNumberedAfterIt():Void
    {
        var plies:Array<RawPly> = line(2);
        var state:LiveGameState = new LiveGameState(info(), [Ply(0, 0, plies[0], null, null, null)], null, null);

        state.apply(Rollback(2, 0, null, null), true);
        Assert.isTrue(state.apply(Ply(1, 1, plies[1], null, null, null), true));

        Assert.equals(0, state.history.plyCount());
    }

    private function testOwnPlyStartsTheOpponentClockFromTheSecondPly():Void
    {
        var plies:Array<RawPly> = line(2);
        var state:LiveGameState = new LiveGameState(info(), [], null, null);

        state.playOwn(plies[0], 1_000);
        Assert.isNull(state.clockAt(1).tickingSide);

        state.playOwn(plies[1], 2_000);
        Assert.equals(White, state.clockAt(2).tickingSide);
    }
}
