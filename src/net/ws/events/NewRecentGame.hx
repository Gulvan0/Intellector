package net.ws.events;

import net.models.game.GameSummaryPublic;
import net.ws.channels.RecentGameList;
import easypubsub.IEvent;

class NewRecentGame implements IEvent<GameSummaryPublic, RecentGameList>
{
}
