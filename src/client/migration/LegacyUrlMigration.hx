package client.migration;

import client.utils.PagePaths;
import js.Browser;
import js.html.URLSearchParams;

/**
    Rewrites the previous version's `?id=<game id>` game links to the `?p=` form the router reads.
    Runs before `HaxeFolioApp.init` reads the URL.
**/
class LegacyUrlMigration
{
    public static function run():Void
    {
        var params:URLSearchParams = new URLSearchParams(Browser.location.search);
        if (params.has("p") || !params.has("id"))
            return;

        var gameId:Null<Int> = Std.parseInt(params.get("id"));
        if (gameId != null)
            Browser.window.history.replaceState(null, "", '${Browser.location.pathname}?p=${PagePaths.liveGame(gameId)}');
    }
}
