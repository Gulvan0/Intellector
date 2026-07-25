package net.ws.events;

import net.models.game.PlyBroadcastedData;
import net.ws.channels.Game;
import easypubsub.IEvent;

class NewPly implements IEvent<PlyBroadcastedData, Game>
{
}
