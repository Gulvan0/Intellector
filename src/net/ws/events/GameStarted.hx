package net.ws.events;

import net.models.game.GamePublic;
import net.ws.channels.StartedPlayerGames;
import lib.pubsub.IEvent;

class GameStarted implements IEvent<GamePublic, StartedPlayerGames>
{
}
