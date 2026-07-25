package net.ws.events;

import net.models.challenge.ChallengePublic;
import net.ws.channels.PublicChallengeList;
import easypubsub.IEvent;

class NewPublicChallenge implements IEvent<ChallengePublic, PublicChallengeList>
{
}
