package net.ws.events;

import net.models.challenge.ChallengeListStateRefresh;
import net.ws.channels.IncomingChallenges;
import lib.pubsub.IEvent;

class IncomingChallengesRefresh implements IEvent<ChallengeListStateRefresh, IncomingChallenges>
{
}
