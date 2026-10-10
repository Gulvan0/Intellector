package client;

import haxefolio.HaxeFolioApp;
import js.Browser;
import js.html.Event;

/**
    Blinks the tab while it's unfocused and incoming challenges have arrived that no tab has shown
    to the user yet. Stops once any tab is focused or every such challenge is resolved.
**/
class IncomingChallengeBlink
{
    private var pendingIds:Array<Int> = [];
    private var unseenIds:Array<Int> = [];

    public function new()
    {
        Browser.window.addEventListener("focus", onFocusMaybeGained);
        Browser.document.addEventListener("visibilitychange", onFocusMaybeGained);
        HaxeFolioApp.valueStorage.addExternalChangeHandler(LocalStorageKey.SEEN_INCOMING_CHALLENGE_IDS, onSeenElsewhere);
    }

    /** The incoming challenges pending now **/
    public function setPending(ids:Array<Int>):Void
    {
        pendingIds = ids;
        forget(id -> !pendingIds.contains(id));
    }

    /** `ids` have just joined the pending ones; ignored while incoming challenges are **/
    public function arrive(ids:Array<Int>):Void
    {
        if (ids.length == 0 || Preferences.silentChallenges.get())
            return;

        if (Browser.document.hasFocus())
        {
            markPendingSeen();
            return;
        }

        var seenIds:Array<Int> = readSeenIds();
        for (id in ids)
            if (!seenIds.contains(id) && !unseenIds.contains(id))
                unseenIds.push(id);

        if (unseenIds.length > 0)
            TabBlink.start(IncomingChallenge);
    }

    private function onFocusMaybeGained(_:Event):Void
    {
        if (!Browser.document.hasFocus())
            return;

        forget(_ -> true);

        if (pendingIds.length > 0)
            markPendingSeen();
    }

    private function onSeenElsewhere(serializedIds:Null<String>):Void
    {
        var seenIds:Array<Int> = parseIds(serializedIds);
        forget(id -> seenIds.contains(id));
    }

    private function forget(predicate:Int->Bool):Void
    {
        unseenIds = unseenIds.filter(id -> !predicate(id));

        if (unseenIds.length == 0)
            TabBlink.stop(IncomingChallenge);
    }

    // every tab lists the same pending challenges, so they replace whatever was stored
    private function markPendingSeen():Void
    {
        HaxeFolioApp.valueStorage.write(LocalStorageKey.SEEN_INCOMING_CHALLENGE_IDS, pendingIds.join(","));
    }

    private function readSeenIds():Array<Int>
    {
        return parseIds(HaxeFolioApp.valueStorage.read(LocalStorageKey.SEEN_INCOMING_CHALLENGE_IDS));
    }

    private static function parseIds(serializedIds:Null<String>):Array<Int>
    {
        if (serializedIds == null || serializedIds == "")
            return [];

        return [for (part in serializedIds.split(",")) Std.parseInt(part)];
    }
}
