package client.ui.common.overlays.playersearch;

import client.datatypes.player.FoundPlayer;
import client.datatypes.player.PlayerSearchResults;
import client.formatters.PlayerSearchFormatters;
import client.utils.PlayerStatusFeed;
import client.utils.TimedLoad;
import haxe.Timer;
import haxe.ui.Toolkit;
import haxefolio.HaxeFolioApp;
import haxefolio.appearance.AppearanceOverrides;
import haxefolio.LocaleUtils;
import haxefolio.overlay.OverlayContent;
import haxefolio.structure.SearchBar;
import net.models.player.mappers.PlayerMapper;
import net.rest.Rest;
import net.rest.RestOperationRegistry;

using StringTools;

/**
    Picking a player by nickname: the best matches update as the user types, their statuses live.
    Picking one closes the overlay, then hands the player to the call site. Cancel closes it with
    nothing picked.
**/
class PlayerSearchOverlay
{
    private static inline final DEBOUNCE_MS:Int = 250;
    private static inline final QUERY_MAX_CHARS:Int = 64;

    /**
        `title` names what the pick is for. `excludeOwn` leaves the user's own account out of the
        results. `initialQuery` is searched right away. `overOpenOverlay` opens it over the overlay
        that is open (and does nothing if there is none) instead of requiring none.
    **/
    public static function present(title:String, excludeOwn:Bool, onPicked:FoundPlayer->Void, initialQuery:String = "", overOpenOverlay:Bool = false):Void
    {
        var appearance:AppearanceOverrides = {
            geometry: {
                dialogWidth: StyleVars.PLAYER_SEARCH_OVERLAY_WIDTH,
                dialogHeight: StyleVars.PLAYER_SEARCH_OVERLAY_HEIGHT,
                headerHeight: StyleVars.PLAYER_SEARCH_OVERLAY_HEADER_HEIGHT,
                searchBarHeight: StyleVars.PLAYER_SEARCH_OVERLAY_SEARCH_HEIGHT
            }
        };
        var factory:(Void->Void)->OverlayContent = build.bind(title, excludeOwn, onPicked, initialQuery);

        if (overOpenOverlay)
            HaxeFolioApp.presentOver("player_search", factory, null, appearance);
        else
            HaxeFolioApp.present("player_search", factory, null, appearance);
    }

    private static function build(title:String, excludeOwn:Bool, onPicked:FoundPlayer->Void, initialQuery:String, dismiss:Void->Void):OverlayContent
    {
        var load:TimedLoad = new TimedLoad();
        var debounce:Null<Timer> = null;
        var searchBar:Null<SearchBar> = null;
        var statusFeed:Null<PlayerStatusFeed> = null;

        function stopDebounce():Void
        {
            if (debounce != null)
                debounce.stop();
            debounce = null;
        }

        function stopStatusFeed():Void
        {
            if (statusFeed != null)
                statusFeed.detach();
            statusFeed = null;
        }

        function pick(player:FoundPlayer):Void
        {
            dismiss();
            onPicked(player);
        }

        var list:PlayerSearchResultList = new PlayerSearchResultList(pick);

        function search(query:String):Void
        {
            var params:Map<String, Any> = ["query" => query, "exclude_self" => excludeOwn];
            load.start(
                (onResponse, onError) -> Rest.client().execute(RestOperationRegistry.SEARCH_PLAYERS, onResponse, onError, null, params),
                response -> {
                    var results:PlayerSearchResults = PlayerMapper.searchResultToDatatype(response);
                    searchBar.message = results.totalCount > 0 ? PlayerSearchFormatters.count(results.totalCount) : null;
                    list.showPlayers(results.players, query);
                    stopStatusFeed();
                    if (results.players.length > 0)
                        statusFeed = new PlayerStatusFeed(results.players.map(player -> player.login), (login, status, _) -> list.setStatus(login, status));
                },
                error -> {
                    stopStatusFeed();
                    searchBar.message = null;
                    list.showFailure(error == null, () -> {
                        list.showRetrying();
                        search(query);
                    });
                }
            );
        }

        function onQuery(text:String):Void
        {
            stopDebounce();
            var query:String = text.trim();

            if (query == "")
            {
                load.cancel();
                stopStatusFeed();
                searchBar.message = null;
                list.showStart();
                return;
            }

            list.showPending();
            debounce = Timer.delay(() -> {
                debounce = null;
                search(query);
            }, DEBOUNCE_MS);
        }

        searchBar = new SearchBar(LocaleUtils.localeBinding("intellector.overlay.player_search.placeholder"), onQuery, true, QUERY_MAX_CHARS);

        if (initialQuery.trim() != "")
        {
            searchBar.query = initialQuery;
            onQuery(initialQuery);
        }

        // the frame is put on screen right after this factory returns
        Toolkit.callLater(searchBar.focus);

        return {
            regions: [
                Header(title, null, true),
                Search(searchBar),
                Scroll(list),
                Custom(StyleVars.PLAYER_SEARCH_OVERLAY_FOOTER_HEIGHT, new PlayerSearchFooter(dismiss))
            ],
            onDismissed: () -> {
                stopDebounce();
                stopStatusFeed();
                load.cancel();
                searchBar.dispose();
            }
        };
    }
}
