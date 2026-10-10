package net.ws.events;

import net.models.game.GameSummaryPublic;
import net.ws.channels.PlayerOngoingGames;
import easypubsub.IEvent;

class OngoingGameStarted implements IEvent<GameSummaryPublic, PlayerOngoingGames>
{
}
