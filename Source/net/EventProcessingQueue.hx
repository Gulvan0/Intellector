package net;

interface INetObserver 
{
    public function handleNetEvent(event:ServerEvent):Void;
}

class EventProcessingQueue
{
    private var observers:Array<INetObserver> = [];
    private var handlers:Array<ServerEvent->Void> = [];

    public function processEvent(event:ServerEvent)
    {
        for (handler in handlers)
            handler(event);
        
        for (obs in observers)
            obs.handleNetEvent(event);
    }

    public function addHandler(handler:ServerEvent->Void)
    {
        handlers.push(handler);
    }

    public function removeHandler(handler:ServerEvent->Void)
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