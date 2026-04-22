package net.ws.events;

import net.models.challenge.ChallengePublic;
import net.ws.channels.PublicChallengeList;
import lib.pubsub.IEvent;

class NewPublicChallenge implements IEvent<ChallengePublic, PublicChallengeList>
{
}
