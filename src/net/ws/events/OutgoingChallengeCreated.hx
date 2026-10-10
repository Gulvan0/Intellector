package net.ws.events;

import net.models.challenge.ChallengePublic;
import net.ws.channels.OutgoingChallenges;
import easypubsub.IEvent;

class OutgoingChallengeCreated implements IEvent<ChallengePublic, OutgoingChallenges>
{
}
