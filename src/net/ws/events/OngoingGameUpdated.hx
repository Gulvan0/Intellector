package net.ws.events;

import net.models.game.OngoingGameUpdate;
import net.ws.channels.PlayerOngoingGames;
import easypubsub.IEvent;

class OngoingGameUpdated implements IEvent<OngoingGameUpdate, PlayerOngoingGames>
{
}
