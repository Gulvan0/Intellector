package client;

import client.datatypes.ChallengeMarks;
import haxefolio.HaxeFolioApp;

/**
    The challenge marks in localStorage, shared by the browser's tabs. Only one user's marks are
    kept: those of another user read as empty.
**/
class ChallengeMarksStorage
{
    public static function read(userRef:String):ChallengeMarks
    {
        return deserialize(HaxeFolioApp.valueStorage.read(LocalStorageKey.CHALLENGE_MARKS), userRef);
    }

    /** Merges `marks` into the ones stored for `userRef` **/
    public static function save(userRef:String, marks:ChallengeMarks):Void
    {
        var merged:ChallengeMarks = read(userRef).merge(marks);
        HaxeFolioApp.valueStorage.write(LocalStorageKey.CHALLENGE_MARKS, serialize(merged, userRef));
    }

    /** `handler` gets the marks another tab stores, read for the user `userRefRetriever` returns then (if any) **/
    public static function addExternalChangeHandler(userRefRetriever:Void->Null<String>, handler:ChallengeMarks->Void):Void
    {
        HaxeFolioApp.valueStorage.addExternalChangeHandler(LocalStorageKey.CHALLENGE_MARKS, serialized -> {
            var userRef:Null<String> = userRefRetriever();
            if (userRef != null)
                handler(deserialize(serialized, userRef));
        });
    }

    // `<seen up to id>;<dismissed ids, comma-separated>;<user ref>`
    private static function serialize(marks:ChallengeMarks, userRef:String):String
    {
        return '${marks.seenUpToId};${marks.dismissedIds.join(",")};$userRef';
    }

    private static function deserialize(serialized:Null<String>, userRef:String):ChallengeMarks
    {
        if (serialized == null)
            return ChallengeMarks.empty();

        var firstSeparator:Int = serialized.indexOf(";");
        var secondSeparator:Int = serialized.indexOf(";", firstSeparator + 1);
        if (firstSeparator == -1 || secondSeparator == -1 || serialized.substr(secondSeparator + 1) != userRef)
            return ChallengeMarks.empty();

        var seenUpToId:Null<Int> = Std.parseInt(serialized.substring(0, firstSeparator));
        var dismissedIds:Array<Int> = [];
        for (part in serialized.substring(firstSeparator + 1, secondSeparator).split(","))
        {
            var id:Null<Int> = Std.parseInt(part);
            if (id != null)
                dismissedIds.push(id);
        }

        return new ChallengeMarks(dismissedIds, seenUpToId ?? 0);
    }
}
