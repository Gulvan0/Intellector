package gfx.live.interfaces;

import gfx.live.events.ChatboxEvent;
import gfx.live.events.GameboardEvent;

interface IGameComponentObserver 
{
    public function handleGameboardEvent(event:GameboardEvent):Void;
    public function handleChatboxEvent(event:ChatboxEvent):Void;
}