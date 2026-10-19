package client.utils;

import client.datatypes.player.PlayerStatus;
import easypubsub.Subscription;
import net.models.player.PlayerStatusState;
import net.models.player.mappers.PlayerMapper;
import net.ws.PubSub;
import net.ws.channels.PlayerStatus as PlayerStatusChannel;
import net.ws.events.PlayerStatusChanged;
import net.ws.events.PlayerStatusRefresh;

/** The live statuses of several players, subscribed to in one batch **/
class PlayerStatusFeed
{
    private final subscriptions:Array<Subscription<PlayerStatusChannel>>;

    /**
        `onStatus` gets a player's login, status and the Unix time of their latest activity in
        milliseconds (null if unknown): once subscribed, then on every change, until `detach`.
    **/
    public function new(logins:Array<String>, onStatus:(login:String, status:PlayerStatus, lastActiveMs:Null<Float>)->Void)
    {
        subscriptions = PubSub.subMany([for (login in logins) new PlayerStatusChannel(login)]);
        for (subscription in subscriptions)
        {
            var login:String = subscription.channel.watchedRef;
            function onState(state:PlayerStatusState):Void
            {
                var lastActiveMs:Null<Float> = state.last_active_unixsecs != null ? state.last_active_unixsecs * 1000.0 : null;
                onStatus(login, PlayerMapper.statusToDatatype(state.status), lastActiveMs);
            }
            subscription.onEventLight(PlayerStatusRefresh, onState).onEventLight(PlayerStatusChanged, onState);
        }
    }

    public function detach():Void
    {
        PubSub.unsubMany(subscriptions);
        subscriptions.resize(0);
    }
}
