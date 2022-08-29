package net;

import net.shared.ServerEvent;

interface INetObserver 
{
    public function handleNetEvent(event:ServerEvent):Void;
}

class EventProcessingQueue
{
    private var observers:Array<INetObserver> = [];
    private var handlers:Array<ServerEvent->Bool> = [];

    public function processEvent(event:ServerEvent)
    {
        for (handler in handlers)
        {
            var destroy:Bool = handler(event);
            if (destroy)
                removeHandler(handler);
        }
        
        for (obs in observers)
            obs.handleNetEvent(event);
    }

    /**Should return true when ready to be removed**/
    public function addHandler(handler:ServerEvent->Bool)
    {
        handlers.push(handler);
    }

    public function removeHandler(handler:ServerEvent->Bool)
    {
        handlers.remove(handler);
    }

    public function removeObserver(observer:INetObserver)
    {
        observers.remove(observer);
    }

    public function addObserver(observer:INetObserver)
    {
        observers.push(observer);
    }

    public function flush()
    {
        observers = [];
        handlers = [];
    }

    public function new() 
    {
        
    }
}