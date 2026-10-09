package client.datatypes;

/**
    The incoming challenges on display: the active one and the others waiting, in arrival order.

    Each challenge is announced once: once off display, it stays off even if `sync` still lists it.
    Removing the active challenge promotes the newest remaining one. While an acceptance is pending,
    the user can't switch the active challenge or reply to the whole queue.
**/
class ChallengeQueue
{
    public var active(get, never):Null<IncomingChallenge>;
    /** In arrival order **/
    public var waiting(get, never):Array<IncomingChallenge>;
    public var accepting(get, never):Bool;

    private var entries:Array<IncomingChallenge> = []; // in arrival order, the active one included
    private var announcedIds:Map<Int, Bool> = [];
    private var activeId:Null<Int> = null;
    private var acceptingId:Null<Int> = null;

    private function get_active():Null<IncomingChallenge>
    {
        return find(activeId);
    }

    private function get_waiting():Array<IncomingChallenge>
    {
        return entries.filter(entry -> entry.id != activeId);
    }

    private function get_accepting():Bool
    {
        return acceptingId != null;
    }

    public function new() {}

    /** Puts `challenge` on display unless announced before **/
    public function announce(challenge:IncomingChallenge):Void
    {
        if (announcedIds.exists(challenge.id))
            return;

        announcedIds.set(challenge.id, true);
        entries.push(challenge);

        if (activeId == null)
            activeId = challenge.id;
    }

    /** Announces new `pending` challenges and removes those no longer listed **/
    public function sync(pending:Array<IncomingChallenge>):Void
    {
        var pendingIds:Map<Int, Bool> = [for (challenge in pending) challenge.id => true];

        for (entry in entries.copy())
            if (!pendingIds.exists(entry.id))
                remove(entry.id);

        var arrivalOrder:Array<IncomingChallenge> = pending.copy();
        arrivalOrder.sort((a, b) -> a.id - b.id);

        for (challenge in arrivalOrder)
            announce(challenge);
    }

    /** Takes challenge `id` off display, if it's there **/
    public function remove(id:Int):Void
    {
        var entry:Null<IncomingChallenge> = find(id);
        if (entry == null)
            return;

        entries.remove(entry);

        if (acceptingId == id)
            acceptingId = null;

        if (activeId == id)
            activeId = entries.length > 0 ? entries[entries.length - 1].id : null;
    }

    /** Takes every challenge off display **/
    public function clear():Void
    {
        entries = [];
        activeId = null;
        acceptingId = null;
    }

    /** `clear` that also forgets announced challenges - for a change of user **/
    public function reset():Void
    {
        announcedIds = [];
        clear();
    }

    /** Makes challenge `id` the active one; ignored while accepting **/
    public function select(id:Int):Void
    {
        if (!accepting && find(id) != null)
            activeId = id;
    }

    /** Marks the active challenge as being accepted and returns it; null if there's none or one already is **/
    public function beginAccept():Null<IncomingChallenge>
    {
        if (accepting || activeId == null)
            return null;

        acceptingId = activeId;
        return active;
    }

    /** Ends the pending acceptance of challenge `id`, keeping it on display **/
    public function acceptFailed(id:Int):Void
    {
        if (acceptingId == id)
            acceptingId = null;
    }

    /** Takes every challenge off display and returns them; nothing while accepting **/
    public function declineAll():Array<IncomingChallenge>
    {
        if (accepting)
            return [];

        var declined:Array<IncomingChallenge> = entries;
        clear();
        return declined;
    }

    /** `clear`, ignored while accepting **/
    public function hideAll():Void
    {
        if (!accepting)
            clear();
    }

    private function find(id:Null<Int>):Null<IncomingChallenge>
    {
        return Lambda.find(entries, entry -> entry.id == id);
    }
}
