package net.ws.events;

import net.models.challenge.ChallengeListStateRefresh;
import net.ws.channels.PublicChallengeList;
import lib.pubsub.IEvent;

class PublicChallengeListRefresh implements IEvent<ChallengeListStateRefresh, PublicChallengeList>
{
}
