package client.ui.common.games;

import client.datatypes.OngoingGame;
import client.ui.common.games.widget.OngoingGamesWidget;

/** Keeps the ongoing games widget in sync with the current user's ongoing games **/
class OngoingGamesController
{
    private final widget:OngoingGamesWidget;

    private var games:Map<Int, OngoingGame> = [];

    public function new(widget:OngoingGamesWidget)
    {
        this.widget = widget;
    }

    /** Replaces every game with `ongoing` **/
    public function sync(ongoing:Array<OngoingGame>):Void
    {
        games = [for (game in ongoing) game.id => game];
        render();
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

    /** Forgets every game - for a change of user **/
    public function reset():Void
    {
        sync([]);
    }

    private function render():Void
    {
        widget.render(Lambda.array(games));
    }
}
