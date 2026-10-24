package client.ui.home;

import client.auth.Identity;
import client.auth.IdentityKeeper;
import client.datatypes.challenge.OpenChallenge;
import client.datatypes.game.GameListFilter;
import client.datatypes.timecontrol.FischerTimeControl;
import client.logic.challenge.creation.ChallengePrefills;
import client.logic.changelog.Changelog;
import client.ui.common.notifications.RequestFailureNotice;
import client.ui.common.overlays.challenge.ChallengeCreationLauncher;
import client.ui.common.overlays.login.LoginOverlay;
import client.ui.home.GamesSection.GamesSectionKind;
import client.utils.TimedLoad;
import easypubsub.Subscription;
import haxe.Timer;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;
import http.HttpError;
import morestd.Detachable;
import net.models.challenge.mappers.OpenChallengeMapper;
import net.models.game.mappers.GameListFilterMapper;
import net.models.game.mappers.GameRecordMapper;
import net.rest.Rest;
import net.rest.RestOperationRegistry;
import net.ws.PubSub;
import net.ws.channels.CurrentGameList;
import net.ws.channels.PublicChallengeList;
import net.ws.channels.RecentGameList;
import net.ws.events.CurrentGameEnded;
import net.ws.events.CurrentGameListRefresh;
import net.ws.events.NewActiveGame;
import net.ws.events.NewPublicChallenge;
import net.ws.events.NewRecentGame;
import net.ws.events.PublicChallengeCancelled;
import net.ws.events.PublicChallengeFulfilled;
import net.ws.events.PublicChallengeListRefresh;
import net.ws.events.PublicChallengesCancelledByServer;
import net.ws.events.RecentGameListRefresh;

/**
    The home page: starting a game, the open challenges (followed live over the public challenge
    list channel), and the ongoing and recent games, each followed live over its own channel: the
    current game list, and the recent game list of the section's filter.
**/
class HomePage extends PageBase
{
    private static inline final CHALLENGES_TIMEOUT_MS:Int = 10000;
    private static inline final GAMES_TIMEOUT_MS:Int = 10000;
    private static inline final CHALLENGE_BATCH_SIZE:Int = 50;
    private static inline final TIME_REFRESH_MS:Int = 60 * 1000;

    private final moreChallengesLoad:TimedLoad = new TimedLoad();

    private var homeLayout:Null<HomeLayout> = null;
    private var challengesCard:Null<OpenChallengesCard> = null;
    private var ongoingSection:Null<GamesSection> = null;
    private var recentSection:Null<GamesSection> = null;

    private var challengesSubscription:Null<Subscription<PublicChallengeList>> = null;
    private var challengesTimer:Null<Timer> = null;
    private var challengesLoaded:Bool = false;
    private var ongoingSubscription:Null<Subscription<CurrentGameList>> = null;
    private var ongoingTimer:Null<Timer> = null;
    private var ongoingLoaded:Bool = false;
    private var recentSubscription:Null<Subscription<RecentGameList>> = null;
    private var recentTimer:Null<Timer> = null;
    private var recentLoaded:Bool = false;
    private var timeRefreshTimer:Null<Timer> = null;
    private var tierHandle:Null<Detachable> = null;
    private var closed:Bool = false;

    public function new()
    {
        super();
    }

    private override function init():Void
    {
        setTitle(LocaleUtils.localeBinding("intellector.home.title"));

        var playCard:PlayCard = new PlayCard(Changelog.load()[0], () -> ChallengeCreationLauncher.launch(null), onPresetPressed);
        challengesCard = new OpenChallengesCard({
            onAccept: acceptChallenge,
            onCancel: cancelChallenge,
            onLoadMore: loadMoreChallenges
        });
        ongoingSection = createSection(Ongoing);
        recentSection = createSection(Recent);

        homeLayout = new HomeLayout(playCard, challengesCard, ongoingSection, recentSection);
        addComponent(homeLayout);
        tierHandle = HomeLayoutTier.bind(tier -> homeLayout.setNarrow(tier == Narrow));

        IdentityKeeper.addChangeListener(onIdentityChanged);
        challengesCard.setViewer(IdentityKeeper.currentIdentity.getUserRef());
        timeRefreshTimer = new Timer(TIME_REFRESH_MS);
        timeRefreshTimer.run = ongoingSection.refreshTimes;

        subscribeChallenges();
        subscribeOngoing();
        subscribeRecent(recentSection.filter);
    }

    private override function onClose():Void
    {
        closed = true;
        IdentityKeeper.removeChangeListener(onIdentityChanged);
        moreChallengesLoad.cancel();
        if (challengesSubscription != null)
            challengesSubscription.detach();
        challengesSubscription = null;
        if (ongoingSubscription != null)
            ongoingSubscription.detach();
        ongoingSubscription = null;
        if (recentSubscription != null)
            recentSubscription.detach();
        recentSubscription = null;
        stopChallengesTimer();
        stopGamesTimers();
        if (timeRefreshTimer != null)
            timeRefreshTimer.stop();
        timeRefreshTimer = null;
        if (tierHandle != null)
            tierHandle.detach();
        tierHandle = null;
        if (homeLayout != null)
            homeLayout.dispose();
        if (challengesCard != null)
            challengesCard.dispose();
        for (section in [ongoingSection, recentSection])
            if (section != null)
                section.dispose();
    }

    private function createSection(kind:GamesSectionKind):GamesSection
    {
        var section:Null<GamesSection> = null;
        section = new GamesSection(kind, {
            onFilterChanged: subscribeRecent,
            onTabSelected: index -> homeLayout.showSection(index),
            onRetry: () -> {
                section.showLoading();
                if (kind == Recent)
                    subscribeRecent(section.filter);
                else
                    subscribeOngoing();
            }
        });
        return section;
    }

    private function onIdentityChanged(identity:Identity):Void
    {
        challengesCard.setViewer(identity.getUserRef());
    }

    private function onPresetPressed(timeControl:FischerTimeControl):Void
    {
        ChallengeCreationLauncher.launch(draft -> ChallengePrefills.timeControl(draft, timeControl));
    }

    private function subscribeChallenges():Void
    {
        if (challengesSubscription != null)
            challengesSubscription.detach();
        moreChallengesLoad.cancel();
        challengesLoaded = false;
        challengesCard.showLoading();

        stopChallengesTimer();
        challengesTimer = Timer.delay(() -> {
            if (!challengesLoaded)
                challengesCard.showFailure(true, subscribeChallenges);
        }, CHALLENGES_TIMEOUT_MS);

        challengesSubscription = PubSub.sub(new PublicChallengeList())
            .onEventLight(PublicChallengeListRefresh, refresh -> {
                stopChallengesTimer();
                moreChallengesLoad.cancel();
                challengesLoaded = true;
                challengesCard.setChallenges(refresh.challenges.map(OpenChallengeMapper.dtoToDatatype), refresh.has_more);
            })
            .onEventLight(NewPublicChallenge, challenge -> challengesCard.addChallenge(OpenChallengeMapper.dtoToDatatype(challenge)))
            .onEventLight(PublicChallengeCancelled, id -> challengesCard.removeChallenge(id.id))
            .onEventLight(PublicChallengeFulfilled, id -> challengesCard.removeChallenge(id.id))
            .onEventLight(PublicChallengesCancelledByServer, idList -> {
                for (id in idList.ids)
                    challengesCard.removeChallenge(id);
            });
    }

    private function stopChallengesTimer():Void
    {
        if (challengesTimer != null)
            challengesTimer.stop();
        challengesTimer = null;
    }

    private function loadMoreChallenges(offset:Int):Void
    {
        moreChallengesLoad.start(
            (onResponse, onError) -> Rest.client().execute(
                RestOperationRegistry.GET_PUBLIC_CHALLENGES,
                onResponse,
                onError,
                null,
                ["offset" => offset, "limit" => CHALLENGE_BATCH_SIZE]
            ),
            response -> challengesCard.appendChallenges(response.parsed.map(OpenChallengeMapper.dtoToDatatype), response.parsed.length == CHALLENGE_BATCH_SIZE),
            error -> challengesCard.showMoreFailure(error == null)
        );
    }

    private function acceptChallenge(challenge:OpenChallenge):Void
    {
        if (challenge.rated && IdentityKeeper.currentIdentity.isGuest())
        {
            LoginOverlay.present();
            return;
        }

        challengesCard.setBusy(challenge.id, true);
        Rest.client().execute(
            RestOperationRegistry.ACCEPT_CHALLENGE,
            game -> HaxeFolioApp.navigateTo('live/${game.id}'),
            error -> {
                if (closed)
                    return;
                challengesCard.setBusy(challenge.id, false);
                if (isChallengeResolved(error))
                {
                    challengesCard.removeChallenge(challenge.id);
                    RequestFailureNotice.show(ACCEPT_CHALLENGE, ChallengeUnavailable);
                }
                else
                    RequestFailureNotice.showHttpError(ACCEPT_CHALLENGE, error);
            },
            ["challenge_id" => Std.string(challenge.id)]
        );
    }

    private function cancelChallenge(challenge:OpenChallenge):Void
    {
        challengesCard.setBusy(challenge.id, true);
        Rest.client().execute(
            RestOperationRegistry.CANCEL_CHALLENGE,
            _ -> {
                if (!closed)
                    challengesCard.removeChallenge(challenge.id);
            },
            error -> {
                if (closed)
                    return;
                challengesCard.setBusy(challenge.id, false);
                if (isChallengeResolved(error))
                    challengesCard.removeChallenge(challenge.id);
                else
                    RequestFailureNotice.showHttpError(CANCEL_CHALLENGE, error);
            },
            ["challenge_id" => Std.string(challenge.id)]
        );
    }

    // not found, or no longer active: cancelled or accepted already
    private static function isChallengeResolved(error:HttpError):Bool
    {
        return error.httpStatus == 404 || error.httpStatus == 422;
    }

    private function subscribeOngoing():Void
    {
        if (ongoingSubscription != null)
            ongoingSubscription.detach();
        ongoingLoaded = false;
        if (ongoingTimer != null)
            ongoingTimer.stop();
        ongoingTimer = Timer.delay(() -> {
            if (!ongoingLoaded)
                ongoingSection.showFailure(true);
        }, GAMES_TIMEOUT_MS);

        ongoingSubscription = PubSub.sub(new CurrentGameList())
            .onEventLight(CurrentGameListRefresh, refresh -> {
                ongoingLoaded = true;
                ongoingSection.setGames(refresh.games.map(GameRecordMapper.summaryToDatatype));
            })
            .onEventLight(NewActiveGame, game -> ongoingSection.addGame(GameRecordMapper.summaryToDatatype(game)))
            .onEventLight(CurrentGameEnded, id -> ongoingSection.removeGame(id.id));
    }

    private function subscribeRecent(filter:GameListFilter):Void
    {
        if (recentSubscription != null)
            recentSubscription.detach();
        recentLoaded = false;
        if (recentTimer != null)
            recentTimer.stop();
        recentTimer = Timer.delay(() -> {
            if (!recentLoaded)
                recentSection.showFailure(true);
        }, GAMES_TIMEOUT_MS);

        recentSubscription = PubSub.sub(GameListFilterMapper.filterToRecentChannel(filter))
            .onEventLight(RecentGameListRefresh, refresh -> {
                recentLoaded = true;
                recentSection.setGames(refresh.games.map(GameRecordMapper.summaryToDatatype));
            })
            .onEventLight(NewRecentGame, game -> recentSection.addGame(GameRecordMapper.summaryToDatatype(game)));
    }

    private function stopGamesTimers():Void
    {
        if (ongoingTimer != null)
            ongoingTimer.stop();
        ongoingTimer = null;
        if (recentTimer != null)
            recentTimer.stop();
        recentTimer = null;
    }
}
