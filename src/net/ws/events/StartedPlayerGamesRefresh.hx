package net.ws.events;

import net.models.player.StartedPlayerGamesStateRefresh;
import net.ws.channels.StartedPlayerGames;
import lib.pubsub.IEvent;

class StartedPlayerGamesRefresh implements IEvent<StartedPlayerGamesStateRefresh, StartedPlayerGames>
{
}
