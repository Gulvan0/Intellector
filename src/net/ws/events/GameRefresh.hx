package net.ws.events;

import net.models.game.GameStateRefresh;
import net.ws.channels.Game;
import easypubsub.IEvent;

class GameRefresh implements IEvent<GameStateRefresh, Game>
{
}
