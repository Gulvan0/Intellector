package gfx.live.interfaces;

import gfx.live.events.ActionBarEvent;
import gfx.live.events.ChatboxEvent;
import gfx.live.events.GameboardEvent;
import gfx.live.events.PlyHistoryViewEvent;

interface IGameComponentObserver 
{
    public function handleGameboardEvent(event:GameboardEvent):Void;
    public function handleChatboxEvent(event:ChatboxEvent):Void;
    public function handleActionBarEvent(event:ActionBarEvent):Void;
    public function handlePlyHistoryViewEvent(event:PlyHistoryViewEvent):Void;
}