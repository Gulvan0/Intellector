package net.shared;

class ServerMessage 
{
    public final id:Int;
    public final event:ServerEvent;    

    public function new(id:Int, event:ServerEvent)
    {
        this.id = id;
        this.event = event;
    }
}