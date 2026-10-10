package net.ws.events;

import net.models.player.PlayerOngoingGamesStateRefresh;
import net.ws.channels.PlayerOngoingGames;
import easypubsub.IEvent;

class PlayerOngoingGamesRefresh implements IEvent<PlayerOngoingGamesStateRefresh, PlayerOngoingGames>
{
}
