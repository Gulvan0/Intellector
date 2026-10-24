package net.ws.events;

import net.models.game.GameSummaryPublic;
import net.ws.channels.CurrentGameList;
import easypubsub.IEvent;

class NewActiveGame implements IEvent<GameSummaryPublic, CurrentGameList>
{
}
