package net.ws.events;

import net.models.game.GameStartedBroadcastedData;
import net.ws.channels.CurrentGameList;
import easypubsub.IEvent;

class NewActiveGame implements IEvent<GameStartedBroadcastedData, CurrentGameList>
{
}
