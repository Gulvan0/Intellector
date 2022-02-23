package net;

class Handler 
{
    private var eventHandlers:Map<ServerEvent, Array<Dynamic>->Void>;
    public var disposable(default, null):Bool;

    public function processEvent(event:ServerEvent):Bool
    {
        var handler = eventHandlers.get(event);
        if (handler != null)
            handler(event.getParameters());
        return handler != null;
    }

    public function assignHandler(event:ServerEvent, handler:Array<Dynamic>->Void) 
    {
        eventHandlers.set(event, handler);
    }

    public function new(disposable:Bool, ?handlers:Map<ServerEvent, Array<Dynamic>->Void>) 
    {
        this.disposable = disposable;
        this.eventHandlers = handlers == null? [] : handlers;
    }    
}