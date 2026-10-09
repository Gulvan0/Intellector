package client.ui.common.notifications.challenges;

import client.datatypes.ChallengeQueue;
import client.datatypes.IncomingChallenge;

/**
    Keeps the incoming challenge notification in sync with the queue of challenges on display.

    Replies go out through `onAccept`/`onDecline`; the owner reports the server's side through the
    public methods.
**/
class IncomingChallengesController
{
    private final queue:ChallengeQueue = new ChallengeQueue();
    private final stack:ChallengeNotificationStack;
    private final onAccept:IncomingChallenge->Void;
    private final onDecline:IncomingChallenge->Void;

    /**
        `onDecline` is called once the challenge is off display. After `onAccept`, the challenge stays
        with its replies disabled until `acceptSucceeded` or `acceptFailed`.
    **/
    public function new(onAccept:IncomingChallenge->Void, onDecline:IncomingChallenge->Void)
    {
        this.onAccept = onAccept;
        this.onDecline = onDecline;

        stack = new ChallengeNotificationStack({
            onRowPressed: onRowPressed,
            onCardClose: onCardClose,
            onCardDecline: onCardDecline,
            onCardAccept: onCardAccept,
            onDeclineAll: onDeclineAll,
            onHideAll: onHideAll
        });
    }

    /** See `ChallengeQueue.announce` **/
    public function announce(challenge:IncomingChallenge):Void
    {
        queue.announce(challenge);
        render();
    }

    /** See `ChallengeQueue.sync` **/
    public function sync(pending:Array<IncomingChallenge>):Void
    {
        queue.sync(pending);
        render();
    }

    /** Takes challenge `id` off display, if it's there **/
    public function remove(id:Int):Void
    {
        queue.remove(id);
        render();
    }

    /** Hides the notification: the accepted challenge's game has started **/
    public function acceptSucceeded():Void
    {
        queue.clear();
        render();
    }

    /** Re-enables the replies of challenge `id` **/
    public function acceptFailed(id:Int):Void
    {
        queue.acceptFailed(id);
        render();
    }

    /** Hides the notification and forgets announced challenges - for a change of user **/
    public function reset():Void
    {
        queue.reset();
        render();
    }

    private function onRowPressed(id:Int):Void
    {
        queue.select(id);
        render();
    }

    private function onCardClose():Void
    {
        queue.remove(queue.active.id);
        render();
    }

    private function onCardDecline():Void
    {
        var challenge:IncomingChallenge = queue.active;
        queue.remove(challenge.id);
        render();
        onDecline(challenge);
    }

    private function onCardAccept():Void
    {
        var challenge:Null<IncomingChallenge> = queue.beginAccept();
        if (challenge == null)
            return;

        render();
        onAccept(challenge);
    }

    private function onDeclineAll():Void
    {
        var declined:Array<IncomingChallenge> = queue.declineAll();
        render();

        for (challenge in declined)
            onDecline(challenge);
    }

    private function onHideAll():Void
    {
        queue.hideAll();
        render();
    }

    private function render():Void
    {
        stack.render(queue.active, queue.waiting, queue.accepting);
    }
}
