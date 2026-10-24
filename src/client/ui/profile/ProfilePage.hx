package client.ui.profile;

import client.auth.Identity;
import client.auth.IdentityKeeper;
import client.datatypes.game.GameRecord;
import client.datatypes.player.ConnectionKind;
import client.datatypes.player.Connections;
import client.datatypes.player.GameStats;
import client.datatypes.player.PlayerRelation;
import client.datatypes.timecontrol.TimeControlKind;
import client.ui.common.notifications.RequestFailureNotice;
import client.ui.common.overlays.login.LoginOverlay;
import client.ui.profile.ProfileState.ArchiveState;
import client.ui.profile.ProfileState.OngoingGamesState;
import client.utils.PlayerStatusFeed;
import client.utils.TimedLoad;
import easypubsub.Subscription;
import haxe.Timer;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;
import haxefolio.PageLink;
import morestd.Detachable;
import net.models.common.mappers.TimeControlKindMapper;
import net.models.game.GameSearchPayload;
import net.models.game.mappers.GameCountsMapper;
import net.models.game.mappers.GameRecordMapper;
import net.models.player.mappers.PlayerMapper;
import net.models.study.ListStudiesPayload;
import net.models.study.mappers.StudySummaryMapper;
import net.rest.Rest;
import net.rest.RestOperationRegistry;
import net.ws.PubSub;
import net.ws.channels.PlayerOngoingGames;
import net.ws.events.OngoingGameEnded;
import net.ws.events.OngoingGameStarted;
import net.ws.events.OngoingGameUpdated;
import net.ws.events.PlayerOngoingGamesRefresh;

/**
    A player's profile. Each card loads on its own: the header (profile, main rating, relation), the
    ongoing games (followed live over the player's ongoing games channel), past games and studies,
    connections, and game stats with the rating history of the picked kind. The statuses of the
    player and their connections are followed live.
**/
class ProfilePage extends PageBase
{
    private static inline final ONGOING_TIMEOUT_MS:Int = 10000;
    private static inline final TIME_REFRESH_MS:Int = 60 * 1000;

    private final login:String;

    private final profileLoad:TimedLoad = new TimedLoad();
    private final statsLoad:TimedLoad = new TimedLoad();
    private final relationLoad:TimedLoad = new TimedLoad();
    private final connectionsLoad:TimedLoad = new TimedLoad();
    private final pastGamesLoad:TimedLoad = new TimedLoad();
    private final studiesLoad:TimedLoad = new TimedLoad();
    private final historyLoad:TimedLoad = new TimedLoad();

    private var profileLayout:Null<ProfileLayout> = null;
    private var header:Null<ProfileHeaderCard> = null;
    private var ongoingCard:Null<OngoingGamesCard> = null;
    private var archiveCard:Null<ArchiveCard> = null;
    private var connectionsCard:Null<ConnectionsCard> = null;
    private var statsCard:Null<GameStatsCard> = null;

    private var ongoingSubscription:Null<Subscription<PlayerOngoingGames>> = null;
    private var ongoingGames:Null<Array<GameRecord>> = null;
    private var ongoingTimer:Null<Timer> = null;
    private var statusFeed:Null<PlayerStatusFeed> = null;
    private var connectionStatusFeed:Null<PlayerStatusFeed> = null;
    private var timeRefreshTimer:Null<Timer> = null;
    private var tierHandle:Null<Detachable> = null;
    private var friendRequestPending:Bool = false;
    private var restoredState:ProfileState = {};

    public function new(login:String)
    {
        super();
        this.login = login;
    }

    private override function init():Void
    {
        setTitle(LocaleUtils.localeBinding("intellector.profile.title"), login);

        restoredState = ProfileStateReader.read(HaxeFolioApp.navigationState);

        header = new ProfileHeaderCard(onFriendPressed, () -> {});
        ongoingCard = new OngoingGamesCard(login, restoredState.ongoing, onOngoingStateChanged);
        archiveCard = new ArchiveCard(login, {
            onPastGamesQuery: loadPastGames,
            onStudiesQuery: loadStudies,
            onStateChanged: onArchiveStateChanged
        }, restoredState.archive);
        connectionsCard = new ConnectionsCard();
        statsCard = new GameStatsCard(loadHistory);

        profileLayout = new ProfileLayout(header, [ongoingCard, archiveCard], [connectionsCard, statsCard]);
        addComponent(profileLayout);
        tierHandle = ProfileLayoutTier.bind(tier -> {
            profileLayout.setTier(tier);
            header.setTier(tier);
            connectionsCard.setTier(tier);
            statsCard.setTier(tier);
        });

        IdentityKeeper.addChangeListener(onIdentityChanged);
        timeRefreshTimer = new Timer(TIME_REFRESH_MS);
        timeRefreshTimer.run = () -> {
            ongoingCard.refreshTimes();
            header.refreshTimes();
        };

        loadProfile();
        loadStats();
        loadRelation();
        loadConnections();
        subscribeOngoing();
        statusFeed = new PlayerStatusFeed([login], (_, status, lastActiveMs) -> header.setStatus(status, lastActiveMs));
        archiveCard.start();
    }

    private override function onClose():Void
    {
        stopUpdates();
        if (profileLayout != null)
            profileLayout.dispose();
        if (ongoingCard != null)
            ongoingCard.dispose();
        if (archiveCard != null)
            archiveCard.dispose();
        if (statsCard != null)
            statsCard.dispose();
    }

    private function stopUpdates():Void
    {
        IdentityKeeper.removeChangeListener(onIdentityChanged);
        for (load in [profileLoad, statsLoad, relationLoad, connectionsLoad, pastGamesLoad, studiesLoad, historyLoad])
            load.cancel();
        if (ongoingSubscription != null)
            ongoingSubscription.detach();
        ongoingSubscription = null;
        if (statusFeed != null)
            statusFeed.detach();
        statusFeed = null;
        stopConnectionStatusFeed();
        stopOngoingTimer();
        if (timeRefreshTimer != null)
            timeRefreshTimer.stop();
        timeRefreshTimer = null;
        if (tierHandle != null)
            tierHandle.detach();
        tierHandle = null;
    }

    private function onOngoingStateChanged(state:OngoingGamesState):Void
    {
        restoredState.ongoing = state;
        HaxeFolioApp.setState(restoredState);
    }

    private function onArchiveStateChanged(state:ArchiveState):Void
    {
        restoredState.archive = state;
        HaxeFolioApp.setState(restoredState);
    }

    private function isOwnProfile():Bool
    {
        return IdentityKeeper.currentIdentity.getLogin() == login;
    }

    private function onIdentityChanged(_:Identity):Void
    {
        loadRelation();
    }

    private function loadProfile():Void
    {
        header.showLoading();
        profileLoad.start(
            (onResponse, onError) -> Rest.client().execute(RestOperationRegistry.GET_PLAYER, onResponse, onError, ["login" => login]),
            response -> header.setProfile(PlayerMapper.profileToDatatype(response)),
            error -> {
                if (error != null && error.httpStatus == 404)
                    showNotFound();
                else
                    header.showFailure(error == null, loadProfile);
            }
        );
    }

    private function loadStats():Void
    {
        statsCard.showLoading();
        statsLoad.start(
            (onResponse, onError) -> Rest.client().execute(RestOperationRegistry.GET_GAME_STATS, onResponse, onError, ["login" => login]),
            response -> {
                var stats:GameStats = PlayerMapper.gameStatsToDatatype(response);
                header.setMainRating(true, stats.mainRating);
                statsCard.setStats(stats);
            },
            error -> statsCard.showFailure(error == null, loadStats)
        );
    }

    private function loadRelation():Void
    {
        relationLoad.cancel();
        if (isOwnProfile())
        {
            header.setRelation(Unrelated, false);
            return;
        }
        if (IdentityKeeper.currentIdentity.isGuest())
        {
            header.setRelation(Unrelated, true);
            return;
        }

        relationLoad.start(
            (onResponse, onError) -> Rest.client().execute(RestOperationRegistry.GET_PLAYER_RELATION, onResponse, onError, ["login" => login]),
            response -> header.setRelation(PlayerMapper.relationToDatatype(response), true),
            _ -> header.setRelation(Unrelated, true)
        );
    }

    private function loadConnections():Void
    {
        connectionsCard.showLoading();
        connectionsLoad.start(
            (onResponse, onError) -> Rest.client().execute(RestOperationRegistry.GET_PLAYER_CONNECTIONS, onResponse, onError, ["login" => login]),
            response -> {
                var connections:Connections = PlayerMapper.connectionsToDatatype(response);
                connectionsCard.setConnections(connections);
                followConnectionStatuses(connections);
            },
            error -> connectionsCard.showFailure(error == null, loadConnections)
        );
    }

    private function followConnectionStatuses(connections:Connections):Void
    {
        stopConnectionStatusFeed();
        var logins:Array<String> = [for (kind in ConnectionKind.createAll()) for (connection in connections.get(kind)) connection.login];
        if (logins.length > 0)
            connectionStatusFeed = new PlayerStatusFeed(logins, (login, status, _) -> connectionsCard.setStatus(login, status));
    }

    private function stopConnectionStatusFeed():Void
    {
        if (connectionStatusFeed != null)
            connectionStatusFeed.detach();
        connectionStatusFeed = null;
    }

    private function loadHistory(kind:TimeControlKind):Void
    {
        historyLoad.start(
            (onResponse, onError) -> Rest.client().execute(
                RestOperationRegistry.GET_ELO_HISTORY,
                onResponse,
                onError,
                ["login" => login],
                ["time_control_kind" => TimeControlKindMapper.datatypeToDto(kind)]
            ),
            response -> statsCard.setHistory(kind, PlayerMapper.ratingHistoryToDatatype(response.parsed)),
            error -> statsCard.showHistoryFailure(kind, error == null, () -> loadHistory(kind))
        );
    }

    private function loadPastGames(kinds:Array<TimeControlKind>, rated:Null<Bool>, page:Int, pageSize:Int, withCounts:Bool):Void
    {
        var payload:GameSearchPayload = {
            player_ref: login,
            time_control_kinds: kinds.length > 0 ? kinds.map(TimeControlKindMapper.datatypeToDto) : null,
            rated: rated,
            finished: true,
            with_counts: withCounts
        };
        pastGamesLoad.start(
            (onResponse, onError) -> Rest.client().execute(
                RestOperationRegistry.SEARCH_GAMES,
                onResponse,
                onError,
                null,
                ["offset" => (page - 1) * pageSize, "limit" => pageSize],
                payload
            ),
            response -> archiveCard.setPastGames(
                response.games.map(GameRecordMapper.summaryToDatatype),
                response.total,
                response.counts != null ? GameCountsMapper.dtoToDatatype(response.counts) : null
            ),
            error -> archiveCard.showPastGamesFailure(error == null)
        );
    }

    private function loadStudies(tags:Array<String>, page:Int, pageSize:Int):Void
    {
        var payload:ListStudiesPayload = {author_login: login, tags: tags.length > 0 ? tags : null};
        studiesLoad.start(
            (onResponse, onError) -> Rest.client().execute(
                RestOperationRegistry.LIST_STUDIES,
                onResponse,
                onError,
                null,
                ["offset" => (page - 1) * pageSize, "limit" => pageSize],
                payload
            ),
            response -> archiveCard.setStudies(response.studies.map(StudySummaryMapper.dtoToDatatype), response.total),
            error -> archiveCard.showStudiesFailure(error == null)
        );
    }

    private function subscribeOngoing():Void
    {
        if (ongoingSubscription != null)
            ongoingSubscription.detach();
        ongoingGames = null;
        ongoingCard.showLoading();

        stopOngoingTimer();
        ongoingTimer = Timer.delay(() -> {
            if (ongoingGames == null)
                ongoingCard.showFailure(true, subscribeOngoing);
        }, ONGOING_TIMEOUT_MS);

        ongoingSubscription = PubSub.sub(new PlayerOngoingGames(login))
            .onEventLight(PlayerOngoingGamesRefresh, refresh -> {
                var opening:Bool = ongoingGames == null;
                stopOngoingTimer();
                ongoingGames = refresh.current_games.map(GameRecordMapper.ongoingToDatatype);
                ongoingCard.setGames(ongoingGames, opening);
            })
            .onEventLight(OngoingGameStarted, started -> updateOngoing(games -> games.concat([GameRecordMapper.summaryToDatatype(started)])))
            .onEventLight(OngoingGameUpdated, update -> updateOngoing(games -> [
                for (game in games)
                    game.id == update.game_id ? GameRecordMapper.applyUpdate(game, update) : game
            ]))
            .onEventLight(OngoingGameEnded, ended -> updateOngoing(games -> games.filter(game -> game.id != ended.id)));
    }

    private function updateOngoing(change:Array<GameRecord>->Array<GameRecord>):Void
    {
        if (ongoingGames == null)
            return;
        ongoingGames = change(ongoingGames);
        ongoingCard.setGames(ongoingGames, false);
    }

    private function stopOngoingTimer():Void
    {
        if (ongoingTimer != null)
            ongoingTimer.stop();
        ongoingTimer = null;
    }

    private function onFriendPressed(relation:PlayerRelation):Void
    {
        if (IdentityKeeper.currentIdentity.isGuest())
        {
            LoginOverlay.present();
            return;
        }
        if (friendRequestPending)
            return;

        var follow:Bool = relation.match(Unrelated | FollowsYou);
        friendRequestPending = true;
        header.setFriendBusy(true);
        Rest.client().execute(
            follow ? RestOperationRegistry.FOLLOW_PLAYER : RestOperationRegistry.UNFOLLOW_PLAYER,
            _ -> {
                onFriendRequestDone();
                loadRelation();
                loadConnections();
            },
            error -> {
                onFriendRequestDone();
                RequestFailureNotice.showHttpError(follow ? FOLLOW_PLAYER : UNFOLLOW_PLAYER, error);
                loadRelation();
            },
            ["login" => login]
        );
    }

    private function onFriendRequestDone():Void
    {
        friendRequestPending = false;
        header.setFriendBusy(false);
    }

    // nothing to retry: the user goes looking for another player
    private function showNotFound():Void
    {
        stopUpdates();
        removeAllComponents();

        var statusBox:VBox = new VBox();
        statusBox.addClass(StyleClass.GAME_STATUS);
        statusBox.horizontalAlign = "center";

        var label:Label = new Label();
        label.text = LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.profile.not_found"), login);
        label.horizontalAlign = "center";
        label.addClass(StyleClass.GAME_STATUS_TEXT);
        statusBox.addComponent(label);

        var actionButton:Button = new Button();
        actionButton.text = LocaleUtils.localeBinding("intellector.live_game.status.to_main_page");
        actionButton.horizontalAlign = "center";
        actionButton.addClass(StyleClass.GAME_BUTTON);
        actionButton.addClass(StyleClass.GAME_BUTTON_PRIMARY);
        PageLink.attach(actionButton, HaxeFolioApp.defaultPagePath);
        statusBox.addComponent(actionButton);

        addComponent(statusBox);
    }
}
