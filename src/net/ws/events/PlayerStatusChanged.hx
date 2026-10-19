package net.ws.events;

import net.models.player.PlayerStatusState;
import net.ws.channels.PlayerStatus;
import easypubsub.IEvent;

class PlayerStatusChanged implements IEvent<PlayerStatusState, PlayerStatus>
{
}
