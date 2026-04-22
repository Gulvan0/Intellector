package net.ws.events;

import net.models.challenge.ChallengeListStateRefresh;
import net.ws.channels.OutgoingChallenges;
import lib.pubsub.IEvent;

class OutgoingChallengesRefresh implements IEvent<ChallengeListStateRefresh, OutgoingChallenges>
{
}
