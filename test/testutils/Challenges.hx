package testutils;

import client.datatypes.IncomingChallenge;

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

    public static function ids(challenges:Array<IncomingChallenge>):Array<Int>
    {
        return challenges.map(challenge -> challenge.id);
    }
}
