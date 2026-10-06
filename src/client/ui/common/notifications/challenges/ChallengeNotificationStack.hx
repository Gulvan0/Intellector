package client.ui.common.notifications.challenges;

import client.datatypes.IncomingChallenge;
import haxe.ui.containers.VBox;
import haxefolio.ByWidth;
import haxefolio.HaxeFolioApp;
import haxefolio.ResponsivityController;
import haxefolio.notification.Notification;

/**
    The incoming challenge notification: the active challenge as a card, the others as rows above
    it, and, for two or more, a bar with group replies on top.

    Each challenge is announced once: once hidden (✕, Hide all, accepting another), it stays hidden
    even if `sync` still lists it. Arrivals enter as the newest row; removing the active challenge
    promotes the newest remaining one.

    Replies go out through `onAccept`/`onDecline`; the owner reports back through `remove`,
    `hideAll` and `acceptFailed`.
**/
class ChallengeNotificationStack extends VBox
{
    private static inline final MAX_ROWS_EXPANDED:Int = 3;
    private static inline final MAX_ROWS_COLLAPSED:Int = 1;

    private final onAccept:IncomingChallenge->Void;
    private final onDecline:IncomingChallenge->Void;
    private final rowBox:VBox;

    // on display, in arrival order
    private var entries:Array<IncomingChallenge> = [];
    private var announcedIds:Map<Int, Bool> = [];
    private var arrivedIds:Map<Int, Bool> = [];
    private var activeId:Null<Int> = null;
    private var acceptingId:Null<Int> = null;
    private var collapsed:Bool = false;
    private var notification:Null<Notification> = null;

    private var bar:Null<ChallengeStackBar> = null;
    private var rows:Map<Int, ChallengeCompactRow> = [];
    private var card:Null<ChallengeCard> = null;

    /**
        `onDecline` is called once the challenge is off display. After `onAccept`, the challenge
        stays with its replies disabled until `hideAll` (success) or `acceptFailed`.
    **/
    public function new(onAccept:IncomingChallenge->Void, onDecline:IncomingChallenge->Void)
    {
        super();

        this.onAccept = onAccept;
        this.onDecline = onDecline;

        addClass(StyleClass.CHALLENGE_STACK);
        verticalSpacing = StyleVars.CHALLENGE_STACK_GAP;

        rowBox = new VBox();
        rowBox.percentWidth = 100;
        rowBox.verticalSpacing = StyleVars.CHALLENGE_STACK_GAP;
        rowBox.hidden = true;
        addComponent(rowBox);

        var breakpoint:ByWidth<Bool> = {expanded: false, collapsed: true};
        ResponsivityController.bind(breakpoint, onBreakpointChanged);
    }

    /** Puts `challenge` on display unless announced before **/
    public function announce(challenge:IncomingChallenge):Void
    {
        if (addEntry(challenge))
            render();
    }

    /** Announces new `pending` challenges and removes those no longer listed **/
    public function sync(pending:Array<IncomingChallenge>):Void
    {
        var pendingIds:Map<Int, Bool> = [for (challenge in pending) challenge.id => true];

        for (entry in entries.copy())
            if (!pendingIds.exists(entry.id))
                removeEntry(entry.id);

        var arrivalOrder:Array<IncomingChallenge> = pending.copy();
        arrivalOrder.sort((a, b) -> a.id - b.id);

        for (challenge in arrivalOrder)
            addEntry(challenge);

        render();
    }

    /** Takes challenge `id` off display, if it's there **/
    public function remove(id:Int):Void
    {
        if (removeEntry(id))
            render();
    }

    /** Takes every challenge off display without replying **/
    public function hideAll():Void
    {
        entries = [];
        activeId = null;
        acceptingId = null;
        render();
    }

    /** `hideAll` that also forgets announced challenges - for a change of user **/
    public function reset():Void
    {
        announcedIds = [];
        arrivedIds = [];
        hideAll();
    }

    /** Re-enables the replies of challenge `id` **/
    public function acceptFailed(id:Int):Void
    {
        if (acceptingId != id)
            return;

        acceptingId = null;

        if (card != null)
            card.setRepliesEnabled(true);
    }

    private function addEntry(challenge:IncomingChallenge):Bool
    {
        if (announcedIds.exists(challenge.id))
            return false;

        announcedIds.set(challenge.id, true);
        entries.push(challenge);

        if (activeId == null)
            activeId = challenge.id;
        else
            arrivedIds.set(challenge.id, true);

        return true;
    }

    private function removeEntry(id:Int):Bool
    {
        var entry:Null<IncomingChallenge> = Lambda.find(entries, entry -> entry.id == id);
        if (entry == null)
            return false;

        entries.remove(entry);
        arrivedIds.remove(id);

        if (acceptingId == id)
            acceptingId = null;

        if (activeId == id)
            activeId = entries.length > 0 ? entries[entries.length - 1].id : null;

        return true;
    }

    private function onCardClose():Void
    {
        remove(activeId);
    }

    private function onCardDecline():Void
    {
        var challenge:IncomingChallenge = card.challenge;
        remove(challenge.id);
        onDecline(challenge);
    }

    private function onCardAccept():Void
    {
        acceptingId = card.challenge.id;
        card.setRepliesEnabled(false);
        card.closePreview();
        onAccept(card.challenge);
    }

    private function onRowPressed(id:Int):Void
    {
        // an acceptance is pending; switching could accept two
        if (acceptingId != null)
            return;

        activeId = id;
        render();
    }

    private function onDeclineAll():Void
    {
        if (acceptingId != null)
            return;

        var declined:Array<IncomingChallenge> = entries.copy();
        hideAll();

        for (challenge in declined)
            onDecline(challenge);
    }

    private function onHideAll():Void
    {
        if (acceptingId == null)
            hideAll();
    }

    private function onBreakpointChanged(collapsed:Bool):Void
    {
        this.collapsed = collapsed;

        // everything is sized per breakpoint, so it's all rebuilt
        if (bar != null)
            removeComponent(bar, true);
        bar = new ChallengeStackBar(collapsed, onDeclineAll, onHideAll);
        addComponentAt(bar, 0);

        for (row in rows)
            rowBox.removeComponent(row, true);
        rows = [];

        if (card != null)
        {
            removeComponent(card, true);
            card = null;
        }

        render();
    }

    private function render():Void
    {
        if (entries.length == 0)
        {
            if (card != null)
            {
                removeComponent(card, true);
                card = null;
            }

            for (row in rows)
                rowBox.removeComponent(row, true);
            rows = [];

            if (notification != null)
            {
                notification.dismiss();
                notification = null;
            }

            return;
        }

        renderCard();

        var waiting:Array<IncomingChallenge> = entries.filter(entry -> entry.id != activeId);
        var maxRows:Int = collapsed ? MAX_ROWS_COLLAPSED : MAX_ROWS_EXPANDED;
        var withRow:Array<IncomingChallenge> = waiting.slice(Std.int(Math.max(0, waiting.length - maxRows)));
        var withoutRowCount:Int = waiting.length - withRow.length;

        renderRows(withRow);

        if (collapsed && withRow.length > 0)
            rows.get(withRow[withRow.length - 1].id).setHiddenCount(withoutRowCount);

        bar.hidden = entries.length < 2;
        updateBar();

        if (notification == null)
            notification = HaxeFolioApp.notify(this, StyleVars.CHALLENGE_STACK_EXPANDED_WIDTH);
    }

    private function renderCard():Void
    {
        if (card != null && card.challenge.id == activeId)
            return;

        if (card != null)
            removeComponent(card, true);

        var active:IncomingChallenge = Lambda.find(entries, entry -> entry.id == activeId);
        card = new ChallengeCard(active, collapsed, onCardClose, onCardDecline, onCardAccept);
        addComponent(card);
    }

    private function renderRows(withRow:Array<IncomingChallenge>):Void
    {
        var shownIds:Map<Int, Bool> = [for (challenge in withRow) challenge.id => true];

        for (id => row in rows)
            if (!shownIds.exists(id))
            {
                rowBox.removeComponent(row, true);
                rows.remove(id);
            }

        for (i in 0...withRow.length)
        {
            var challenge:IncomingChallenge = withRow[i];
            var row:Null<ChallengeCompactRow> = rows.get(challenge.id);

            if (row == null)
            {
                row = new ChallengeCompactRow(challenge, collapsed, onRowPressed.bind(challenge.id));
                rows.set(challenge.id, row);
                rowBox.addComponentAt(row, i);

                if (arrivedIds.exists(challenge.id))
                    row.highlightArrival();
            }
            else if (rowBox.getComponentIndex(row) != i)
                rowBox.setComponentIndex(row, i);

            row.setHiddenCount(0);
        }

        // highlighted only when it first gets a row
        for (challenge in withRow)
            arrivedIds.remove(challenge.id);

        rowBox.hidden = withRow.length == 0;
    }

    private function updateBar():Void
    {
        if (bar == null || entries.length == 0)
            return;

        var waitingCount:Int = entries.length - 1;
        var maxRows:Int = collapsed ? MAX_ROWS_COLLAPSED : MAX_ROWS_EXPANDED;
        var withoutRowCount:Int = collapsed ? 0 : Std.int(Math.max(0, waitingCount - maxRows));
        bar.setCounts(entries.length, withoutRowCount);
    }
}
