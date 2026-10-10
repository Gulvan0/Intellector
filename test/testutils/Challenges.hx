package testutils;

import client.datatypes.IncomingChallenge;
import client.datatypes.OutgoingChallenge;

class Challenges
{
    public static function make(id:Int):IncomingChallenge
    {
        return new IncomingChallenge(id, 'caller$id', 'Caller $id', None, Correspondence, false, Random, null);
    }

    public static function makeAll(ids:Array<Int>):Array<IncomingChallenge>
    {
        return ids.map(make);
    }

    public static function makeOutgoing(id:Int):OutgoingChallenge
    {
        return new OutgoingChallenge(id, 'callee$id', 'Callee $id', None, Correspondence, false, Random, null);
    }

    public static function makeAllOutgoing(ids:Array<Int>):Array<OutgoingChallenge>
    {
        return ids.map(makeOutgoing);
    }

    public static function ids(challenges:Array<IncomingChallenge>):Array<Int>
    {
        return challenges.map(challenge -> challenge.id);
    }

    public static function outgoingIds(challenges:Array<OutgoingChallenge>):Array<Int>
    {
        return challenges.map(challenge -> challenge.id);
    }
}
