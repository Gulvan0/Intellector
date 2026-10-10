package client.ui.demo;

import client.datatypes.IncomingChallenge;
import client.datatypes.OutgoingChallenge;
import haxe.Timer;
import http.HttpError;

enum DemoReplyOutcome
{
    Success;
    NoConnection;
    ServerError;
    ChallengeGone;
}

/**
    Stands in for the server for the demo page's fake challenges: feeds them to the app's challenges
    controller and answers the user's replies to them, which never reach the real server.
**/
class DemoChallengeServer
{
    private static inline final FIRST_ID:Int = 1000000000; // above any real challenge id
    private static inline final REPLY_DELAY_MS:Int = 1500;

    /** How the user's replies to fake challenges end **/
    public static var replyOutcome:DemoReplyOutcome = Success;
    /** A fake challenge has been made in this tab, so its challenge marks are fake too **/
    public static var used(default, null):Bool = false;

    private static var nextId:Int = FIRST_ID;
    private static var incomingIds:Array<Int> = [];
    private static var outgoing:Array<OutgoingChallenge> = [];

    public static function takeId():Int
    {
        used = true;
        return nextId++;
    }

    public static function owns(id:Int):Bool
    {
        return incomingIds.contains(id) || Lambda.exists(outgoing, challenge -> challenge.id == id);
    }

    public static function receive(challenge:IncomingChallenge):Void
    {
        incomingIds.push(challenge.id);
        Main.challenges.receiveIncoming(challenge);
    }

    public static function send(challenge:OutgoingChallenge):Void
    {
        outgoing.push(challenge);
        Main.challenges.addOutgoing(challenge);
    }

    /** The caller withdraws their oldest (or newest) fake challenge **/
    public static function callerCancels(newest:Bool):Void
    {
        var id:Null<Int> = newest ? incomingIds.pop() : incomingIds.shift();
        if (id != null)
            Main.challenges.removeIncoming(id);
    }

    /** The callee rejects the oldest fake outgoing challenge **/
    public static function calleeRejects():Void
    {
        var challenge:Null<OutgoingChallenge> = outgoing.shift();
        if (challenge != null)
            Main.challenges.removeOutgoing(challenge.id);
    }

    public static function clear():Void
    {
        for (id in incomingIds)
            Main.challenges.removeIncoming(id);
        for (challenge in outgoing)
            Main.challenges.removeOutgoing(challenge.id);

        incomingIds = [];
        outgoing = [];
    }

    public static function accept(challenge:IncomingChallenge, onFailed:HttpError->Void):Void
    {
        reply(challenge.id, Main.challenges.acceptSucceeded, onFailed);
    }

    public static function decline(challenge:IncomingChallenge, onFailed:HttpError->Void):Void
    {
        reply(challenge.id, () -> {}, onFailed);
    }

    public static function cancel(challenge:OutgoingChallenge, onFailed:HttpError->Void):Void
    {
        reply(challenge.id, () -> {}, onFailed);
    }

    // a failed reply leaves the challenge pending, unless it's gone
    private static function reply(id:Int, onSucceeded:Void->Void, onFailed:HttpError->Void):Void
    {
        Timer.delay(() -> {
            var error:Null<HttpError> = switch replyOutcome {
                case Success: null;
                case NoConnection: new HttpError("Demo: no connection");
                case ServerError: new HttpError("Demo: server error", 500);
                case ChallengeGone: new HttpError("Demo: challenge not found", 404);
            }

            if (error == null || replyOutcome == ChallengeGone)
                forget(id);

            if (error == null)
                onSucceeded();
            else
                onFailed(error);
        }, REPLY_DELAY_MS);
    }

    private static function forget(id:Int):Void
    {
        incomingIds.remove(id);
        outgoing = outgoing.filter(challenge -> challenge.id != id);
    }
}
