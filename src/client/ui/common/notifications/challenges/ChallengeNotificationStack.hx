package client.ui.common.notifications.challenges;

import client.datatypes.IncomingChallenge;
import haxe.ui.containers.VBox;
import haxefolio.ByWidth;
import haxefolio.HaxeFolioApp;
import haxefolio.ResponsivityController;
import haxefolio.notification.Notification;

/**
    The incoming challenge notification: the active challenge as a card, the waiting ones as rows
    above it, and, for two or more, a bar with group replies on top. Shown while there's an active
    challenge.
**/
@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/notifications/challenge_notification_stack.xml"))
class ChallengeNotificationStack extends VBox
{
    private final handlers:ChallengeStackHandlers;

    private var active:Null<IncomingChallenge> = null;
    private var waiting:Array<IncomingChallenge> = [];
    private var accepting:Bool = false;

    private var collapsed:Bool = false;
    private var notification:Null<Notification> = null;
    private var bar:ChallengeStackBar;
    private var rows:Map<Int, ChallengeCompactRow> = [];
    private var card:Null<ChallengeCard> = null;
    private var shownIds:Map<Int, Bool> = []; // with a card or a row since the stack was last empty

    public function new(handlers:ChallengeStackHandlers)
    {
        super();

        this.handlers = handlers;

        bar = new ChallengeStackBar(handlers.onDeclineAll, handlers.onHideAll);
        bar.hidden = true;
        addComponentAt(bar, 0);

        var breakpoint:ByWidth<Bool> = {expanded: false, collapsed: true};
        ResponsivityController.bind(breakpoint, onBreakpointChanged);
    }

    /**
        Shows `active` as the card and `waiting` (in arrival order) as rows; `accepting` disables the
        card's replies. A row is highlighted when a challenge first gets one.
    **/
    public function render(active:Null<IncomingChallenge>, waiting:Array<IncomingChallenge>, accepting:Bool):Void
    {
        this.active = active;
        this.waiting = waiting;
        this.accepting = accepting;
        update();
    }

    // the row limit is the only thing that changes with the breakpoint; the rest is styled per breakpoint
    private function onBreakpointChanged(collapsed:Bool):Void
    {
        this.collapsed = collapsed;
        update();
    }

    private function update():Void
    {
        if (active == null)
        {
            removeCard();
            removeRows();
            shownIds = [];

            if (notification != null)
            {
                notification.dismiss();
                notification = null;
            }

            return;
        }

        var layout:ChallengeStackLayout = new ChallengeStackLayout(waiting, collapsed);

        updateCard();
        updateRows(layout.rows);

        if (layout.rows.length > 0)
            rows.get(layout.rows[layout.rows.length - 1].id).setHiddenCount(layout.rowHiddenCount);

        bar.hidden = waiting.length == 0;
        bar.setCounts(waiting.length + 1, layout.barHiddenCount);

        if (notification == null)
            notification = HaxeFolioApp.notify(this, StyleVars.CHALLENGE_STACK_EXPANDED_WIDTH);
    }

    private function updateCard():Void
    {
        if (card == null || card.challenge.id != active.id)
        {
            removeCard();
            card = new ChallengeCard(active, handlers.onCardClose, handlers.onCardDecline, handlers.onCardAccept);
            addComponent(card);
            shownIds.set(active.id, true);
        }

        card.setRepliesEnabled(!accepting);

        if (accepting)
            card.closePreview();
    }

    private function updateRows(withRow:Array<IncomingChallenge>):Void
    {
        var withRowIds:Map<Int, Bool> = [for (challenge in withRow) challenge.id => true];

        for (id => row in rows)
            if (!withRowIds.exists(id))
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
                row = new ChallengeCompactRow(challenge, handlers.onRowPressed.bind(challenge.id));
                rows.set(challenge.id, row);
                rowBox.addComponentAt(row, i);

                if (!shownIds.exists(challenge.id))
                    row.highlightArrival();
                shownIds.set(challenge.id, true);
            }
            else if (rowBox.getComponentIndex(row) != i)
                rowBox.setComponentIndex(row, i);

            row.setHiddenCount(0);
        }

        rowBox.hidden = withRow.length == 0;
    }

    private function removeCard():Void
    {
        if (card == null)
            return;

        removeComponent(card, true);
        card = null;
    }

    private function removeRows():Void
    {
        for (row in rows)
            rowBox.removeComponent(row, true);
        rows = [];
    }
}
