package client.tabs;

import client.storage.LocalStorageKey;
import client.ui.Sounds;
import haxefolio.HaxeFolioApp;

/**
    Plays the incoming challenge sound in one tab only: every tab receives the challenge, so the
    first one to get here claims it through storage and the rest stay quiet.
**/
class IncomingChallengeSound
{
    /** `ids`: the incoming challenges that have just arrived **/
    public static function play(ids:Array<Int>):Void
    {
        var latestId:Int = 0;
        for (id in ids)
            if (id > latestId)
                latestId = id;

        if (latestId <= readSoundedId())
            return;

        HaxeFolioApp.valueStorage.write(LocalStorageKey.SOUNDED_INCOMING_CHALLENGE_ID, Std.string(latestId));
        Sounds.play(SOCIAL);
    }

    private static function readSoundedId():Int
    {
        var serializedId:Null<String> = HaxeFolioApp.valueStorage.read(LocalStorageKey.SOUNDED_INCOMING_CHALLENGE_ID);
        return serializedId != null ? (Std.parseInt(serializedId) ?? 0) : 0;
    }
}
