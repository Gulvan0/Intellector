package net.ws.events;

import net.models.game.GameStartedBroadcastedData;
import net.ws.channels.CurrentGameList;
import lib.pubsub.IEvent;

class NewActiveGame implements IEvent<GameStartedBroadcastedData, CurrentGameList>
{
}
