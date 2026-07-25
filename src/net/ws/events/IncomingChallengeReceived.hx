package net.ws.events;

import net.models.challenge.ChallengePublic;
import net.ws.channels.IncomingChallenges;
import easypubsub.IEvent;

class IncomingChallengeReceived implements IEvent<ChallengePublic, IncomingChallenges>
{
}
