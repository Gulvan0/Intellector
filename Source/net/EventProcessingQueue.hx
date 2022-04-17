package net;

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

    public function addHandler(handler:ServerEvent->Bool)
    {
        handlers.push(handler);
    }

    public function removeHandler(handler:ServerEvent->Bool)
    {
        handlers.remove(handler);
    }

    public function removeObserser(observer:INetObserver)
    {
        observers.remove(observer);
    }

    public function addObserver(observer:INetObserver)
    {
        observers.push(observer);
    }

    public function new() 
    {
        
    }
}