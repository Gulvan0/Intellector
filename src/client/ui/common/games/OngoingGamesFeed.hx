package client.ui.common.games;

import client.auth.Identity;
import client.ui.common.games.widget.OngoingGamesWidget;
import easypubsub.Subscription;
import net.models.game.mappers.OngoingGameMapper;
import net.ws.PubSub;
import net.ws.channels.PlayerOngoingGames;
import net.ws.events.OngoingGameEnded;
import net.ws.events.OngoingGameStarted;
import net.ws.events.OngoingGameUpdated;
import net.ws.events.PlayerOngoingGamesRefresh;

/** Feeds the user's ongoing games to the `OngoingGamesController` from the server **/
class OngoingGamesFeed
{
    private final games:OngoingGamesController;

    private var subscription:Null<Subscription<PlayerOngoingGames>> = null;

    public function new(widget:OngoingGamesWidget)
    {
        games = new OngoingGamesController(widget);
    }

    /** Starts following the games of the new identity instead of the previous one's **/
    public function onIdentityChanged(identity:Identity):Void
    {
        if (subscription != null)
        {
            subscription.detach();
            subscription = null;
        }

        games.reset();

        var userRef:Null<String> = identity.getUserRef();
        if (userRef == null)
            return;

        subscription = PubSub.sub(new PlayerOngoingGames(userRef))
            .onEventLight(PlayerOngoingGamesRefresh, refresh -> games.sync([for (game in refresh.current_games) OngoingGameMapper.dtoToDatatype(game, userRef)]))
            .onEventLight(OngoingGameStarted, game -> games.add(OngoingGameMapper.startedToDatatype(game, userRef)))
            .onEventLight(OngoingGameUpdated, update -> games.update(update.game_id, game -> OngoingGameMapper.applyUpdate(game, update)))
            .onEventLight(OngoingGameEnded, ended -> games.remove(ended.id));
    }
}
