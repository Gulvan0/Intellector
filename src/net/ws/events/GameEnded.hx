package net.ws.events;

import net.models.game.GameEndedBroadcastedData;
import net.ws.channels.Game;
import lib.pubsub.IEvent;

class GameEnded implements IEvent<GameEndedBroadcastedData, Game>
{
}
