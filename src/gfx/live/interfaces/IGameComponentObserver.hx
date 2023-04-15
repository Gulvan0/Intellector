package gfx.live.interfaces;

import gfx.live.events.GameboardEvent;

interface IGameComponentObserver 
{
    public function handleGameboardEvent(event:GameboardEvent):Void;
}