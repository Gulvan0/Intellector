package net.ws.events;

import net.models.challenge.ChallengePublic;
import net.ws.channels.IncomingChallenges;
import lib.pubsub.IEvent;

class IncomingChallengeReceived implements IEvent<ChallengePublic, IncomingChallenges>
{
}
