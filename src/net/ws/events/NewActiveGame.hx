package net.ws.events;

import net.models.game.GameStartedBroadcastedData;
import net.ws.channels.GameList;
import lib.pubsub.IEvent;

class NewActiveGame implements IEvent<GameStartedBroadcastedData, GameList>
{
}
