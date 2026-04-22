package net.ws.events;

import net.models.game.RollbackBroadcastedData;
import net.ws.channels.Game;
import lib.pubsub.IEvent;

class Rollback implements IEvent<RollbackBroadcastedData, Game>
{
}
