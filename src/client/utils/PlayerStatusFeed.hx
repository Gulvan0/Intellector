package client.utils;

import client.datatypes.player.PlayerStatus;
import easypubsub.SubscriptionGroup;
import net.models.player.PlayerStatusState;
import net.models.player.mappers.PlayerMapper;
import net.ws.PubSub;
import net.ws.channels.PlayerStatus as PlayerStatusChannel;
import net.ws.events.PlayerStatusChanged;
import net.ws.events.PlayerStatusRefresh;

/** The live statuses of several players, subscribed to in one batch **/
class PlayerStatusFeed
{
    private final group:SubscriptionGroup<PlayerStatusChannel>;

    /**
        `onStatus` gets a player's login, status and the Unix time of their latest activity in
        milliseconds (null if unknown): once subscribed, then on every change, until `detach`.
    **/
    public function new(logins:Array<String>, onStatus:(login:String, status:PlayerStatus, lastActiveMs:Null<Float>)->Void)
    {
        function onState(state:PlayerStatusState, channel:PlayerStatusChannel):Void
        {
            var lastActiveMs:Null<Float> = state.last_active_unixsecs != null ? state.last_active_unixsecs * 1000.0 : null;
            onStatus(channel.watchedRef, PlayerMapper.statusToDatatype(state.status), lastActiveMs);
        }

        group = PubSub.subGroup([for (login in logins) new PlayerStatusChannel(login)]);
        group.onEvent(PlayerStatusRefresh, onState).onEvent(PlayerStatusChanged, onState);
    }

    public function detach():Void
    {
        group.detach();
    }
}
