package net.ws.events;

import net.models.game.TimeAddedBroadcastedData;
import net.ws.channels.Game;
import lib.pubsub.IEvent;

class TimeAdded implements IEvent<TimeAddedBroadcastedData, Game>
{
}
