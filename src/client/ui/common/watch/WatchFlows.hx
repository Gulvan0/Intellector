package client.ui.common.watch;

import client.auth.IdentityKeeper;
import client.datatypes.game.OngoingGame;
import client.datatypes.player.FoundPlayer;
import client.datatypes.watch.WatchedGameReactionKind;
import client.datatypes.watch.WatchedPlayer;
import client.logic.watch.WatchedGameReaction;
import client.tabs.WatchedGameClaim;
import client.ui.common.notifications.WatchedGameNotice;
import client.ui.common.overlays.playersearch.PlayerSearchOverlay;
import client.ui.common.watch.widget.WatchWidget;
import client.utils.PagePaths;
import client.utils.PlayerStatusFeed;
import client.watch.WatchKeeper;
import easypubsub.Subscription;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import net.models.game.OngoingGamePublic;
import net.models.game.mappers.OngoingGameMapper;
import net.ws.PubSub;
import net.ws.channels.PlayerOngoingGames;
import net.ws.events.OngoingGameEnded;
import net.ws.events.OngoingGameStarted;
import net.ws.events.OngoingGameUpdated;
import net.ws.events.PlayerOngoingGamesRefresh;

/** What reacting to a game the watched player starts takes knowing about the live game page **/
typedef OpenGameInfo =
{
    /** The game the page shows, null while none is open **/
    openGameId:Void->Null<Int>,
    isShowingOwnOngoingTimedGame:Void->Bool,
    isShowingOthersOngoingTimedGame:Void->Bool
}

/** The watched player: feeds their games and status to the `WatchController`, and reacts to a game they start **/
class WatchFlows
{
    private final watch:WatchController;
    private final openGame:OpenGameInfo;

    private var gamesSubscription:Null<Subscription<PlayerOngoingGames>> = null;
    private var statusFeed:Null<PlayerStatusFeed> = null;

    public function new(widget:WatchWidget, openGame:OpenGameInfo)
    {
        watch = new WatchController(widget);
        this.openGame = openGame;
        WatchedGameClaim.init(reactToGame, announceGame);
    }

    /** Lets the user pick the player to watch **/
    public static function presentPlayerSearch():Void
    {
        PlayerSearchOverlay.present(LocaleUtils.localeBinding("intellector.overlay.player_search.title.watch_player"), true, watchFoundPlayer);
    }

    private static function watchFoundPlayer(player:FoundPlayer):Void
    {
        WatchKeeper.watch(new WatchedPlayer(player.login, player.nickname));
    }

    /** Starts following the new player instead of the previous one **/
    public function onWatchedChanged(player:Null<WatchedPlayer>):Void
    {
        if (gamesSubscription != null)
        {
            gamesSubscription.detach();
            gamesSubscription = null;
        }

        if (statusFeed != null)
        {
            statusFeed.detach();
            statusFeed = null;
        }

        watch.setPlayer(player);

        if (player == null)
            return;

        var login:String = player.login;
        gamesSubscription = PubSub.sub(new PlayerOngoingGames(login))
            .onEventLight(PlayerOngoingGamesRefresh, refresh -> onGamesRefresh(refresh.current_games, login))
            .onEventLight(OngoingGameStarted, started -> {
                var game:OngoingGame = OngoingGameMapper.startedToDatatype(started, login);
                watch.add(game);
                if (!involvesUser(started.white_player.user_ref, started.black_player.user_ref))
                    onGameStarted(game);
            })
            .onEventLight(OngoingGameUpdated, update -> watch.update(update.game_id, game -> OngoingGameMapper.applyUpdate(game, update)))
            .onEventLight(OngoingGameEnded, ended -> {
                watch.remove(ended.id);
                WatchedGameClaim.cancel(ended.id);
                WatchedGameNotice.dismissFor(ended.id);
            });
        statusFeed = new PlayerStatusFeed([login], (_, status, _) -> watch.setStatus(status));
    }

    // a game listed anew after a reconnect may have started meanwhile
    private function onGamesRefresh(dtos:Array<OngoingGamePublic>, login:String):Void
    {
        var games:Array<OngoingGame> = [for (dto in dtos) OngoingGameMapper.dtoToDatatype(dto, login)];
        var newIds:Array<Int> = watch.sync(games);

        for (i in 0...dtos.length)
            if (newIds.contains(dtos[i].id) && !involvesUser(dtos[i].white_player.user_ref, dtos[i].black_player.user_ref))
                onGameStarted(games[i]);
    }

    // the user's own games open through GameRedirect
    private function involvesUser(whiteRef:String, blackRef:String):Bool
    {
        var userRef:Null<String> = IdentityKeeper.currentIdentity.getUserRef();
        return userRef != null && (whiteRef == userRef || blackRef == userRef);
    }

    private function onGameStarted(game:OngoingGame):Void
    {
        if (game.id != openGame.openGameId())
            WatchedGameClaim.request(game);
    }

    private function reactToGame(game:OngoingGame):Void
    {
        var reaction:WatchedGameReactionKind = WatchedGameReaction.decide(
            Preferences.watchedGameOpening.get(),
            HaxeFolioApp.currentPageMayBeLeft(),
            openGame.isShowingOwnOngoingTimedGame(),
            openGame.isShowingOthersOngoingTimedGame()
        );

        switch reaction
        {
            case Navigate:
                WatchedGameNotice.dismissFor(game.id);
                HaxeFolioApp.navigateTo(PagePaths.liveGame(game.id));
            case Announce:
                announceGame(game);
        }
    }

    private function announceGame(game:OngoingGame):Void
    {
        var player:Null<WatchedPlayer> = WatchKeeper.watched;
        if (player != null)
            WatchedGameNotice.show(player.nickname, game);
    }
}
