package net.ws.events;

import net.models.game.CurrentGameListStateRefresh;
import net.ws.channels.CurrentGameList;
import easypubsub.IEvent;

class CurrentGameListRefresh implements IEvent<CurrentGameListStateRefresh, CurrentGameList>
{
}
