package net;

interface INetObserver 
{
    public function handleNetEvent(event:ServerEvent):Void;
}

class EventProcessingQueue
{
    private var observers:Array<INetObserver> = [];
    private var handlers:Array<Handler> = [];

    public function processEvent(event:ServerEvent)
    {
        var i:Int = 0;
        while (i < handlers.length)
        {
            var handler = handlers[i];
            var wasProcessed:Bool = handler.processEvent(event);
            if (handler.disposable && wasProcessed)
                handlers.splice(i, 1);
            else
                i++;
        }
        
        for (obs in observers)
            obs.handleNetEvent(event);
    }

    public function addHandler(handler:Handler)
    {
        handlers.push(handler);
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