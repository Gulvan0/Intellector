package net.ws.events;

import net.models.game.RecentGameListStateRefresh;
import net.ws.channels.RecentGameList;
import easypubsub.IEvent;

class RecentGameListRefresh implements IEvent<RecentGameListStateRefresh, RecentGameList>
{
}
