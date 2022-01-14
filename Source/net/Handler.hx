package net;

class Handler 
{
    private var eventHandlers:Map<String, Dynamic->Void>;
    public var disposable(default, null):Bool;

    public function processEvent(event:ServerEvent):Bool
    {
        var handler = eventHandlers.get(event.getName());
        if (handler != null)
            handler(event.getParameters()[0]);
        return handler != null;
    }

    public function assignHandler(event:ServerEvent, handler:Dynamic->Void) 
    {
        eventHandlers.set(event.getName(), handler);
    }

    public function new(disposable:Bool, ?handlers:Map<ServerEvent, Dynamic->Void> = []) 
    {
        this.disposable = disposable;
        this.eventHandlers = handlers;
    }    
}