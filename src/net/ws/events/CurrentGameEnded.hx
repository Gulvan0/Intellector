package net.ws.events;

import net.models.common.Id;
import net.ws.channels.CurrentGameList;
import easypubsub.IEvent;

class CurrentGameEnded implements IEvent<Id, CurrentGameList>
{
}
