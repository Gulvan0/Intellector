package net.ws.events;

import net.models.common.Id;
import net.ws.channels.IncomingChallenges;
import lib.pubsub.IEvent;

class IncomingChallengeCancelled implements IEvent<Id, IncomingChallenges>
{
}
