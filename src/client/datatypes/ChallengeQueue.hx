package client.datatypes;

/**
    The incoming challenges on display in the notification: the active one and the others waiting,
    in arrival order.

    Each challenge is announced once: once off display, or skipped, it never comes back. Removing
    the active challenge promotes the newest remaining one.
**/
class ChallengeQueue
{
    public var active(get, never):Null<IncomingChallenge>;
    /** In arrival order **/
    public var waiting(get, never):Array<IncomingChallenge>;
    /** In arrival order, the active one included **/
    public var all(get, never):Array<IncomingChallenge>;

    private var entries:Array<IncomingChallenge> = [];
    private var announcedIds:Map<Int, Bool> = [];
    private var activeId:Null<Int> = null;

    private function get_active():Null<IncomingChallenge>
    {
        return find(activeId);
    }

    private function get_waiting():Array<IncomingChallenge>
    {
        return entries.filter(entry -> entry.id != activeId);
    }

    private function get_all():Array<IncomingChallenge>
    {
        return entries.copy();
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

    /** Counts challenge `id` as announced without putting it on display **/
    public function skip(id:Int):Void
    {
        announcedIds.set(id, true);
    }

    /** Takes challenge `id` off display, if it's there **/
    public function remove(id:Int):Void
    {
        var entry:Null<IncomingChallenge> = find(id);
        if (entry == null)
            return;

        entries.remove(entry);

        if (activeId == id)
            activeId = entries.length > 0 ? entries[entries.length - 1].id : null;
    }

    /** Takes every challenge off display **/
    public function clear():Void
    {
        entries = [];
        activeId = null;
    }

    /** `clear` that also forgets announced challenges - for a change of user **/
    public function reset():Void
    {
        announcedIds = [];
        clear();
    }

    /** Makes challenge `id` the active one, if it's on display **/
    public function select(id:Int):Void
    {
        if (find(id) != null)
            activeId = id;
    }

    private function find(id:Null<Int>):Null<IncomingChallenge>
    {
        return Lambda.find(entries, entry -> entry.id == id);
    }
}
