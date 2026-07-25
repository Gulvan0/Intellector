package net.ws.events;

import net.models.game.TimeAddedBroadcastedData;
import net.ws.channels.Game;
import easypubsub.IEvent;

class TimeAdded implements IEvent<TimeAddedBroadcastedData, Game>
{
}
