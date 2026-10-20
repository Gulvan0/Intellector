package client.ui.common.games.widget;

import client.ServerTime;
import client.datatypes.game.OngoingGame;
import client.logic.game.OngoingGameOrdering;
import haxe.ui.containers.VBox;
import haxefolio.ByWidth;
import haxefolio.ResponsivityController;

/** The ongoing games widget's dropdown content: the games in two sections **/
@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/games/widget/ongoing_game_list.xml"))
class OngoingGameList extends VBox
{
    private final onFollowed:Void->Void;
    private final onPreviewToggled:OngoingGameEntry->Bool->Void;

    private var games:Array<OngoingGame> = [];
    private var currentGameId:Null<Int> = null;

    private var entryMap:Map<Int, OngoingGameEntry> = [];

    /** `onFollowed` is called when an entry's link is used to navigate in the app **/
    public function new(onFollowed:Void->Void, onPreviewToggled:OngoingGameEntry->Bool->Void)
    {
        super();

        this.onFollowed = onFollowed;
        this.onPreviewToggled = onPreviewToggled;

        // entries are laid out for one breakpoint, so they're rebuilt for the other
        var breakpoint:ByWidth<Bool> = {expanded: false, collapsed: true};
        ResponsivityController.bind(breakpoint, _ -> rebuild());
    }

    /** `currentGameId` is the game open on the page, if any **/
    public function render(games:Array<OngoingGame>, currentGameId:Null<Int>):Void
    {
        this.games = games;
        this.currentGameId = currentGameId;
        update();
    }

    public function findEntry(id:Int):Null<OngoingGameEntry>
    {
        return entryMap.get(id);
    }

    /** Refreshes every clock and time since the last move **/
    public function updateTime():Void
    {
        var nowMs:Float = ServerTime.now();
        for (entry in entryMap)
            entry.updateTime(nowMs);
    }

    private function rebuild():Void
    {
        for (entry in entryMap)
            entry.parentComponent.removeComponent(entry, true);

        entryMap = [];
        update();
    }

    private function update():Void
    {
        var timed:Array<OngoingGame> = OngoingGameOrdering.timed(games.filter(game -> game.isTimed()), ServerTime.now());
        var correspondence:Array<OngoingGame> = OngoingGameOrdering.correspondence(games.filter(game -> !game.isTimed()));

        var shownIds:Map<Int, Bool> = [for (game in games) game.id => true];
        var goneIds:Array<Int> = [for (id in entryMap.keys()) if (!shownIds.exists(id)) id];
        for (id in goneIds)
        {
            var entry:OngoingGameEntry = entryMap.get(id);
            entry.parentComponent.removeComponent(entry, true);
            entryMap.remove(id);
        }

        updateSection(timedEntries, timed);
        updateSection(correspondenceEntries, correspondence);

        timedCount.text = Std.string(timed.length);
        correspondenceCount.text = Std.string(correspondence.length);
        noTimed.hidden = timed.length > 0;
        noCorrespondence.hidden = correspondence.length > 0;
        timedEntries.hidden = timed.length == 0;
        correspondenceEntries.hidden = correspondence.length == 0;
    }

    // `games` in display order
    private function updateSection(box:VBox, games:Array<OngoingGame>):Void
    {
        for (i in 0...games.length)
        {
            var game:OngoingGame = games[i];
            var entry:Null<OngoingGameEntry> = entryMap.get(game.id);

            if (entry == null)
            {
                entry = new OngoingGameEntry(game, onFollowed);
                entry.onPreviewToggled = onPreviewToggled.bind(entry);
                box.addComponentAt(entry, i);
                entryMap.set(game.id, entry);
            }
            else
            {
                entry.setGame(game);
                if (box.getComponentIndex(entry) != i)
                    box.setComponentIndex(entry, i);
            }

            entry.setFirst(i == 0);
            entry.setGroupBoundary(i > 0 && games[i - 1].isOwnMove() && !game.isOwnMove());
            entry.setCurrent(game.id == currentGameId);
        }
    }
}
