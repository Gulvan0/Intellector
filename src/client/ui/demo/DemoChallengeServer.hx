package client.ui.demo;

import client.datatypes.IncomingChallenge;
import client.datatypes.OutgoingChallenge;
import haxe.Timer;

/**
    Stands in for the server for the demo page's fake challenges: feeds them to the app's challenges
    controller and answers the user's replies to them, which never reach the real server.
**/
class DemoChallengeServer
{
    private static inline final FIRST_ID:Int = 1000000000; // above any real challenge id
    private static inline final ACCEPT_DELAY_MS:Int = 1500;

    /** Whether accepting a fake challenge starts its game rather than failing **/
    public static var acceptSucceeds:Bool = false;
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

    public static function accept(challenge:IncomingChallenge):Void
    {
        Timer.delay(() -> {
            if (acceptSucceeds)
            {
                incomingIds.remove(challenge.id);
                Main.challenges.acceptSucceeded();
            }
            else
                Main.challenges.acceptFailed(challenge.id);
        }, ACCEPT_DELAY_MS);
    }

    public static function decline(challenge:IncomingChallenge):Void
    {
        incomingIds.remove(challenge.id);
    }

    public static function cancel(challenge:OutgoingChallenge):Void
    {
        outgoing = outgoing.filter(pending -> pending.id != challenge.id);
    }
}
