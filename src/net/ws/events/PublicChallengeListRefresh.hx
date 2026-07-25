package net.ws.events;

import net.models.challenge.ChallengeListStateRefresh;
import net.ws.channels.PublicChallengeList;
import easypubsub.IEvent;

class PublicChallengeListRefresh implements IEvent<ChallengeListStateRefresh, PublicChallengeList>
{
}
