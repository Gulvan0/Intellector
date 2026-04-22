package net.ws.events;

import net.models.game.GameListChannelsStateRefresh;
import net.ws.channels.GameList;
import lib.pubsub.IEvent;

class GameListRefresh implements IEvent<GameListChannelsStateRefresh, GameList>
{
}
