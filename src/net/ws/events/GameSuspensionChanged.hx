package net.ws.events;

import net.models.game.GameSuspensionBroadcastedData;
import net.ws.channels.Game;
import easypubsub.IEvent;

class GameSuspensionChanged implements IEvent<GameSuspensionBroadcastedData, Game>
{
}
