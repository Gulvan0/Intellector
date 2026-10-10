package client.ui.common.challenges.widget;

import client.datatypes.IncomingChallenge;
import client.datatypes.OutgoingChallenge;
import haxe.ui.containers.VBox;
import haxefolio.ByWidth;
import haxefolio.ResponsivityController;

/** The challenges widget's dropdown content: the pending challenges in two sections **/
@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/challenges/widget/challenge_list.xml"))
class ChallengeList extends VBox
{
    private final handlers:ChallengesWidgetHandlers;
    private final onPreviewToggled:ChallengeEntry->Bool->Void;

    private var incoming:Array<IncomingChallenge> = [];
    private var outgoing:Array<OutgoingChallenge> = [];
    private var accepting:Bool = false;

    private var incomingEntryMap:Map<Int, ChallengeEntry> = [];
    private var outgoingEntryMap:Map<Int, ChallengeEntry> = [];

    public function new(handlers:ChallengesWidgetHandlers, onPreviewToggled:ChallengeEntry->Bool->Void)
    {
        super();

        this.handlers = handlers;
        this.onPreviewToggled = onPreviewToggled;

        /*
            HaxeUI doesn't unset a percent width a stylesheet rule stops giving, so entries laid out
            for one breakpoint are rebuilt for the other
        */
        var breakpoint:ByWidth<Bool> = {expanded: false, collapsed: true};
        ResponsivityController.bind(breakpoint, _ -> rebuild());
    }

    /** `incoming` and `outgoing` in arrival order; `accepting` disables the replies **/
    public function render(incoming:Array<IncomingChallenge>, outgoing:Array<OutgoingChallenge>, accepting:Bool):Void
    {
        this.incoming = incoming;
        this.outgoing = outgoing;
        this.accepting = accepting;
        update();
    }

    public function findEntry(id:Int):Null<ChallengeEntry>
    {
        return incomingEntryMap.get(id) ?? outgoingEntryMap.get(id);
    }

    private function rebuild():Void
    {
        for (entry in incomingEntryMap)
            incomingEntries.removeComponent(entry, true);
        for (entry in outgoingEntryMap)
            outgoingEntries.removeComponent(entry, true);

        incomingEntryMap = [];
        outgoingEntryMap = [];
        update();
    }

    private function update():Void
    {
        var newestIncoming:Array<IncomingChallenge> = incoming.copy();
        newestIncoming.reverse();
        var newestOutgoing:Array<OutgoingChallenge> = outgoing.copy();
        newestOutgoing.reverse();

        incomingEntryMap = updateSection(incomingEntries, incomingEntryMap, [for (challenge in newestIncoming) challenge.id], index -> {
            var challenge:IncomingChallenge = newestIncoming[index];
            return ChallengeEntry.incoming(challenge, handlers.onDecline.bind(challenge.id), handlers.onAccept.bind(challenge.id));
        });
        outgoingEntryMap = updateSection(outgoingEntries, outgoingEntryMap, [for (challenge in newestOutgoing) challenge.id], index -> {
            var challenge:OutgoingChallenge = newestOutgoing[index];
            return ChallengeEntry.outgoing(challenge, handlers.onCancel.bind(challenge.id));
        });

        for (entry in incomingEntryMap)
            entry.setRepliesEnabled(!accepting);

        incomingCount.text = Std.string(incoming.length);
        outgoingCount.text = Std.string(outgoing.length);
        noIncoming.hidden = incoming.length > 0;
        noOutgoing.hidden = outgoing.length > 0;
        incomingEntries.hidden = incoming.length == 0;
        outgoingEntries.hidden = outgoing.length == 0;
    }

    // `ids` in display order; returns the new id-to-entry map
    private function updateSection(box:VBox, entryMap:Map<Int, ChallengeEntry>, ids:Array<Int>, createEntry:Int->ChallengeEntry):Map<Int, ChallengeEntry>
    {
        var shownIds:Map<Int, Bool> = [for (id in ids) id => true];
        var updatedMap:Map<Int, ChallengeEntry> = [];

        for (id => entry in entryMap)
            if (!shownIds.exists(id))
                box.removeComponent(entry, true);

        for (i in 0...ids.length)
        {
            var entry:Null<ChallengeEntry> = entryMap.get(ids[i]);

            if (entry == null)
            {
                entry = createEntry(i);
                entry.onPreviewToggled = onPreviewToggled.bind(entry);
                box.addComponentAt(entry, i);
            }
            else if (box.getComponentIndex(entry) != i)
                box.setComponentIndex(entry, i);

            entry.setFirst(i == 0);
            updatedMap.set(ids[i], entry);
        }

        return updatedMap;
    }
}
