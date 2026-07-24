package net.ws.events;

import net.models.game.GameEndedBroadcastedData;
import net.ws.channels.CurrentGameList;
import lib.pubsub.IEvent;

class NewRecentGame implements IEvent<GameEndedBroadcastedData, CurrentGameList>
{
}
