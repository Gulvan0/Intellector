package client.datatypes;

/**
    The current user's pending challenges, incoming and outgoing, together with the incoming ones on
    display in the notification - one source of truth for the notification and the challenges widget.

    While an acceptance is pending, no other challenge can be accepted or declined, and the
    notification can neither switch its active challenge nor hide everything at once.

    `marks` are shared with the other tabs: a dismissed challenge never reaches the notification,
    and a pending incoming challenge above the seen id is unseen.
**/
class ChallengeInbox
{
    /** In arrival order **/
    public var incoming(get, never):Array<IncomingChallenge>;
    /** In arrival order **/
    public var outgoing(get, never):Array<OutgoingChallenge>;
    /** What's on display in the notification; changed only through the inbox **/
    public final notification:ChallengeQueue = new ChallengeQueue();
    public var acceptingId(default, null):Null<Int> = null;
    public var accepting(get, never):Bool;
    /** A pending incoming challenge arrived after the last `markSeen` **/
    public var hasUnseenIncoming(get, never):Bool;
    public var marks(default, null):ChallengeMarks = ChallengeMarks.empty();

    private var incomingList:Array<IncomingChallenge> = [];
    private var outgoingList:Array<OutgoingChallenge> = [];

    private function get_incoming():Array<IncomingChallenge>
    {
        return incomingList.copy();
    }

    private function get_outgoing():Array<OutgoingChallenge>
    {
        return outgoingList.copy();
    }

    private function get_accepting():Bool
    {
        return acceptingId != null;
    }

    private function get_hasUnseenIncoming():Bool
    {
        return Lambda.exists(incomingList, challenge -> challenge.id > marks.seenUpToId);
    }

    public function new() {}

    /**
        Adds `challenge` to the pending ones unless it's there already, and puts it on display in
        the notification unless dismissed. Without `notify` (the user is looking at the pending
        list), it's dismissed and seen at once.
    **/
    public function receive(challenge:IncomingChallenge, notify:Bool):Void
    {
        if (findIncoming(challenge.id) != null)
            return;

        incomingList.push(challenge);

        if (!notify)
            addMarks([challenge.id], challenge.id);

        if (marks.dismissedIds.contains(challenge.id))
            notification.skip(challenge.id);
        else
            notification.announce(challenge);
    }

    /** Receives new `pending` challenges, oldest first, and removes those no longer listed **/
    public function syncIncoming(pending:Array<IncomingChallenge>, notify:Bool):Void
    {
        var pendingIds:Map<Int, Bool> = [for (challenge in pending) challenge.id => true];

        for (challenge in incomingList.copy())
            if (!pendingIds.exists(challenge.id))
                removeIncoming(challenge.id);

        var arrivalOrder:Array<IncomingChallenge> = pending.copy();
        arrivalOrder.sort((a, b) -> a.id - b.id);

        for (challenge in arrivalOrder)
            receive(challenge, notify);
    }

    /** Drops incoming challenge `id` from everywhere, as it got resolved; a pending acceptance of it lasts until its outcome is reported **/
    public function removeIncoming(id:Int):Void
    {
        var challenge:Null<IncomingChallenge> = findIncoming(id);
        if (challenge == null)
            return;

        incomingList.remove(challenge);
        notification.remove(id);
    }

    /** Removes incoming challenge `id` and returns it, to be declined; null while accepting **/
    public function decline(id:Int):Null<IncomingChallenge>
    {
        var challenge:Null<IncomingChallenge> = findIncoming(id);
        if (accepting || challenge == null)
            return null;

        removeIncoming(id);
        return challenge;
    }

    /** Puts `challenge` back after a failed decline, in the notification too unless dismissed **/
    public function restoreIncoming(challenge:IncomingChallenge):Void
    {
        if (findIncoming(challenge.id) != null)
            return;

        incomingList.push(challenge);
        incomingList.sort((a, b) -> a.id - b.id);

        if (!marks.dismissedIds.contains(challenge.id))
            notification.restore(challenge);
    }

    /** Removes every challenge on display in the notification and returns them, to be declined; nothing while accepting **/
    public function declineNotified():Array<IncomingChallenge>
    {
        if (accepting)
            return [];

        var declined:Array<IncomingChallenge> = notification.all;

        for (challenge in declined)
            removeIncoming(challenge.id);

        return declined;
    }

    /** Takes challenge `id` off the notification only **/
    public function hideNotified(id:Int):Void
    {
        addMarks([id], 0);
        notification.remove(id);
    }

    /** Takes every challenge off the notification only; ignored while accepting **/
    public function hideAllNotified():Void
    {
        if (!accepting)
            dismissNotified();
    }

    /** Makes challenge `id` the notification's active one; ignored while accepting **/
    public function selectNotified(id:Int):Void
    {
        if (!accepting)
            notification.select(id);
    }

    /** Marks incoming challenge `id` as being accepted and returns it; null if it isn't pending or one already is **/
    public function beginAccept(id:Int):Null<IncomingChallenge>
    {
        var challenge:Null<IncomingChallenge> = findIncoming(id);
        if (accepting || challenge == null)
            return null;

        acceptingId = id;
        return challenge;
    }

    /** Ends the pending acceptance of challenge `id`, keeping it pending **/
    public function acceptFailed(id:Int):Void
    {
        if (acceptingId == id)
            acceptingId = null;
    }

    /** Drops the accepted challenge and clears the notification; the others stay pending **/
    public function acceptSucceeded():Void
    {
        if (acceptingId != null)
            removeIncoming(acceptingId);

        acceptingId = null;
        dismissNotified();
    }

    /** Adds `challenge` to the outgoing ones unless it's there already **/
    public function addOutgoing(challenge:OutgoingChallenge):Void
    {
        if (findOutgoing(challenge.id) != null)
            return;

        outgoingList.push(challenge);
        outgoingList.sort((a, b) -> a.id - b.id);
    }

    /** Replaces the outgoing challenges with `pending` and returns the ones no longer listed **/
    public function syncOutgoing(pending:Array<OutgoingChallenge>):Array<OutgoingChallenge>
    {
        var pendingIds:Map<Int, Bool> = [for (challenge in pending) challenge.id => true];
        var dropped:Array<OutgoingChallenge> = outgoingList.filter(challenge -> !pendingIds.exists(challenge.id));

        outgoingList = pending.copy();
        outgoingList.sort((a, b) -> a.id - b.id);

        return dropped;
    }

    /** Removes outgoing challenge `id` and returns it; null if it isn't pending **/
    public function removeOutgoing(id:Int):Null<OutgoingChallenge>
    {
        var challenge:Null<OutgoingChallenge> = findOutgoing(id);
        if (challenge != null)
            outgoingList.remove(challenge);

        return challenge;
    }

    /** The user has looked at the pending incoming challenges **/
    public function markSeen():Void
    {
        for (challenge in incomingList)
            addMarks([], challenge.id);
    }

    /** Merges `external` into the marks, taking the newly dismissed challenges off the notification **/
    public function applyMarks(external:ChallengeMarks):Void
    {
        marks = marks.merge(external);

        for (id in marks.dismissedIds)
            notification.remove(id);
    }

    /** Forgets everything - for a change of user **/
    public function reset():Void
    {
        incomingList = [];
        outgoingList = [];
        acceptingId = null;
        marks = ChallengeMarks.empty();
        notification.reset();
    }

    private function findIncoming(id:Int):Null<IncomingChallenge>
    {
        return Lambda.find(incomingList, challenge -> challenge.id == id);
    }

    private function findOutgoing(id:Int):Null<OutgoingChallenge>
    {
        return Lambda.find(outgoingList, challenge -> challenge.id == id);
    }

    private function dismissNotified():Void
    {
        addMarks([for (challenge in notification.all) challenge.id], 0);
        notification.clear();
    }

    private function addMarks(dismissedIds:Array<Int>, seenUpToId:Int):Void
    {
        marks = marks.merge(new ChallengeMarks(dismissedIds, seenUpToId));
    }
}
