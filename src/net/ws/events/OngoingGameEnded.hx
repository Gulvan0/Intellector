package net.ws.events;

import net.models.common.Id;
import net.ws.channels.PlayerOngoingGames;
import easypubsub.IEvent;

class OngoingGameEnded implements IEvent<Id, PlayerOngoingGames>
{
}
