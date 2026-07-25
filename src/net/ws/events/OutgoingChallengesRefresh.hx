package net.ws.events;

import net.models.challenge.ChallengeListStateRefresh;
import net.ws.channels.OutgoingChallenges;
import easypubsub.IEvent;

class OutgoingChallengesRefresh implements IEvent<ChallengeListStateRefresh, OutgoingChallenges>
{
}
