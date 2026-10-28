package client.ui.common.watch;

import client.datatypes.game.OngoingGame;
import client.datatypes.player.PlayerStatus;
import client.datatypes.watch.WatchedPlayer;
import client.ui.common.watch.widget.WatchWidget;

/** Keeps the watch widget in sync with the watched player and their ongoing games **/
class WatchController
{
    private final widget:WatchWidget;

    private var games:Map<Int, OngoingGame> = [];
    private var synced:Bool = false;

    public function new(widget:WatchWidget)
    {
        this.widget = widget;
    }

    /** Forgets the games of the previous player, if any **/
    public function setPlayer(player:Null<WatchedPlayer>):Void
    {
        games = [];
        synced = false;
        widget.setPlayer(player);
    }

    public function setStatus(status:PlayerStatus):Void
    {
        widget.setStatus(status);
    }

    /**
        Replaces every game with `ongoing`. Returns the ids of the games it lists anew, except on the
        first sync for a player, whose games were all going already.
    **/
    public function sync(ongoing:Array<OngoingGame>):Array<Int>
    {
        var newIds:Array<Int> = synced ? [for (game in ongoing) if (!games.exists(game.id)) game.id] : [];
        games = [for (game in ongoing) game.id => game];
        synced = true;
        render();
        return newIds;
    }

    public function add(game:OngoingGame):Void
    {
        games.set(game.id, game);
        render();
    }

    /** Replaces game `id` with what `change` makes of it; ignored for a game not listed **/
    public function update(id:Int, change:OngoingGame->OngoingGame):Void
    {
        var game:Null<OngoingGame> = games.get(id);
        if (game == null)
            return;

        games.set(id, change(game));
        render();
    }

    public function remove(id:Int):Void
    {
        if (games.remove(id))
            render();
    }

    private function render():Void
    {
        widget.setGames(Lambda.array(games));
    }
}
