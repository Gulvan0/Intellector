package client.ui.common.challenges;

import client.datatypes.ChallengeInbox;
import client.datatypes.ChallengeMarks;
import client.datatypes.IncomingChallenge;
import client.datatypes.OutgoingChallenge;
import client.ui.common.challenges.widget.ChallengesWidget;
import client.ui.common.notifications.challenges.ChallengeNotificationStack;

/**
    Keeps the incoming challenge notification and the challenges widget in sync with the pending
    challenges, and keeps one position preview open at a time across the two.

    Replies go out through `onAccept`/`onDecline`/`onCancel`; the owner reports the server's side
    through the public methods. The marks shared with the other tabs go out through `onMarksChanged`
    and come in through `applyMarks`.
**/
class ChallengesController
{
    private final inbox:ChallengeInbox = new ChallengeInbox();
    private final stack:ChallengeNotificationStack;
    private final widget:ChallengesWidget;
    private final onAccept:IncomingChallenge->Void;
    private final onDecline:IncomingChallenge->Void;
    private final onCancel:OutgoingChallenge->Void;
    private final onMarksChanged:ChallengeMarks->Void;

    /**
        `onDecline` and `onCancel` are called once the challenge is off display. After `onAccept`,
        every reply stays disabled until `acceptSucceeded` or `acceptFailed`. `onMarksChanged` may be
        called with unchanged marks.
    **/
    public function new(widget:ChallengesWidget, onAccept:IncomingChallenge->Void, onDecline:IncomingChallenge->Void, onCancel:OutgoingChallenge->Void, onMarksChanged:ChallengeMarks->Void)
    {
        this.widget = widget;
        this.onAccept = onAccept;
        this.onDecline = onDecline;
        this.onCancel = onCancel;
        this.onMarksChanged = onMarksChanged;

        stack = new ChallengeNotificationStack({
            onRowPressed: onRowPressed,
            onCardClose: onCardClose,
            onCardDecline: onCardDecline,
            onCardAccept: onCardAccept,
            onDeclineAll: onDeclineAll,
            onHideAll: onHideAll,
            onPreviewOpened: widget.closePreview
        });

        widget.handlers = {
            onAccept: accept,
            onDecline: decline,
            onCancel: cancel,
            onPreviewOpened: stack.closePreview
        };
        widget.dropdown.onOpened = onDropdownOpened;

        render();
    }

    /** A new incoming challenge: notified, unless the widget's dropdown is open **/
    public function receiveIncoming(challenge:IncomingChallenge):Void
    {
        var newIds:Array<Int> = newIncomingIds(() -> inbox.receive(challenge, !widget.dropdown.isOpen));
        render();
        highlightInDropdown(newIds);
    }

    /** See `ChallengeInbox.syncIncoming` **/
    public function syncIncoming(pending:Array<IncomingChallenge>):Void
    {
        var newIds:Array<Int> = newIncomingIds(() -> inbox.syncIncoming(pending, !widget.dropdown.isOpen));
        render();
        highlightInDropdown(newIds);
    }

    /** The other side or the server resolved incoming challenge `id` **/
    public function removeIncoming(id:Int):Void
    {
        inbox.removeIncoming(id);
        render();
    }

    public function addOutgoing(challenge:OutgoingChallenge):Void
    {
        inbox.addOutgoing(challenge);
        render();
    }

    /** Replaces the outgoing challenges with `pending` and returns the ones no longer listed **/
    public function syncOutgoing(pending:Array<OutgoingChallenge>):Array<OutgoingChallenge>
    {
        var dropped:Array<OutgoingChallenge> = inbox.syncOutgoing(pending);
        render();
        return dropped;
    }

    /** The other side or the server resolved outgoing challenge `id` **/
    public function removeOutgoing(id:Int):Void
    {
        inbox.removeOutgoing(id);
        render();
    }

    /** Closes the widget's dropdown and the notification: the accepted challenge's game has started **/
    public function acceptSucceeded():Void
    {
        inbox.acceptSucceeded();
        widget.dropdown.close();
        render();
    }

    /** Re-enables the replies after a failed acceptance of challenge `id` **/
    public function acceptFailed(id:Int):Void
    {
        inbox.acceptFailed(id);
        render();
    }

    /** Marks made in another tab **/
    public function applyMarks(marks:ChallengeMarks):Void
    {
        inbox.applyMarks(marks);
        render();
    }

    /** Forgets every challenge and mark - for a change of user **/
    public function reset():Void
    {
        inbox.reset();
        render();
    }

    private function accept(id:Int):Void
    {
        var challenge:Null<IncomingChallenge> = inbox.beginAccept(id);
        if (challenge == null)
            return;

        render();
        onAccept(challenge);
    }

    private function decline(id:Int):Void
    {
        var challenge:Null<IncomingChallenge> = inbox.decline(id);
        if (challenge == null)
            return;

        render();
        onDecline(challenge);
    }

    private function cancel(id:Int):Void
    {
        var challenge:Null<OutgoingChallenge> = inbox.removeOutgoing(id);
        if (challenge == null)
            return;

        render();
        onCancel(challenge);
    }

    private function onRowPressed(id:Int):Void
    {
        inbox.selectNotified(id);
        render();
    }

    private function onCardClose():Void
    {
        inbox.hideNotified(inbox.notification.active.id);
        render();
    }

    private function onCardDecline():Void
    {
        decline(inbox.notification.active.id);
    }

    private function onCardAccept():Void
    {
        accept(inbox.notification.active.id);
    }

    private function onDeclineAll():Void
    {
        var declined:Array<IncomingChallenge> = inbox.declineNotified();
        render();

        for (challenge in declined)
            onDecline(challenge);
    }

    private function onHideAll():Void
    {
        inbox.hideAllNotified();
        render();
    }

    private function onDropdownOpened():Void
    {
        inbox.markSeen();
        render();
    }

    // the ids `change` adds to the pending incoming challenges
    private function newIncomingIds(change:Void->Void):Array<Int>
    {
        var previousIds:Map<Int, Bool> = [for (challenge in inbox.incoming) challenge.id => true];
        change();
        return [for (challenge in inbox.incoming) if (!previousIds.exists(challenge.id)) challenge.id];
    }

    private function highlightInDropdown(ids:Array<Int>):Void
    {
        if (!widget.dropdown.isOpen)
            return;

        for (id in ids)
            widget.highlightArrival(id);
    }

    private function render():Void
    {
        stack.render(inbox.notification.active, inbox.notification.waiting, inbox.accepting);
        widget.render(inbox.incoming, inbox.outgoing, inbox.accepting, inbox.hasUnseenIncoming);
        onMarksChanged(inbox.marks);
    }
}
