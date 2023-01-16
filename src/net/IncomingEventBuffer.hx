package net;

import net.shared.utils.MathUtils;
import net.shared.ServerMessage;
import net.shared.ServerEvent;

class IncomingEventBuffer 
{
    public var lastProcessedEventID(default, null):Int = 0;
    public var maxReceivedEventID(default, null):Int = 0;

    private var eventProcessorCallback:ServerEvent->Void;
    private var resendNeededCallback:(from:Int, to:Int)->Void;

    public function push(message:ServerMessage) 
    {
        if (message.id > maxReceivedEventID)
        {
            if (maxReceivedEventID == lastProcessedEventID && message.id == maxReceivedEventID + 1)
            {
                eventProcessorCallback(message.event);
                lastProcessedEventID = message.id;
            }
            else
                resendNeededCallback(lastProcessedEventID + 1, message.id);

            maxReceivedEventID = message.id;
        }
        else if (message.id == -1)
            eventProcessorCallback(message.event);
    }

    public function pushMissed(missedEvents:Map<Int, ServerEvent>) 
    {
        var nextEventID:Int = lastProcessedEventID + 1;

        while (missedEvents.exists(nextEventID))
        {
            eventProcessorCallback(missedEvents[nextEventID]);
            lastProcessedEventID = nextEventID;
            nextEventID++;
        }

        maxReceivedEventID = MathUtils.maxInt(maxReceivedEventID, lastProcessedEventID);
    }

    public function isWaiting() 
    {
        return maxReceivedEventID > lastProcessedEventID;
    }

    public function new(eventProcessorCallback:ServerEvent->Void, resendNeededCallback:(from:Int, to:Int)->Void) 
    {
        this.eventProcessorCallback = eventProcessorCallback;
        this.resendNeededCallback = resendNeededCallback;
    }
}