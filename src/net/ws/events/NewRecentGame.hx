package net.ws.events;

import net.models.game.GameEndedBroadcastedData;
import net.ws.channels.GameList;
import lib.pubsub.IEvent;

class NewRecentGame implements IEvent<GameEndedBroadcastedData, GameList>
{
}
