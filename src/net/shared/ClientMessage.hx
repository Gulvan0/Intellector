package net.shared;

class ClientMessage 
{
    public final id:Int;
    public final event:ClientEvent;    

    public function new(id:Int, event:ClientEvent)
    {
        this.id = id;
        this.event = event;
    }
}