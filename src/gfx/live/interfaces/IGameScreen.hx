package gfx.live.interfaces;

import net.INetObserver;
import gfx.live.events.VariationViewEvent;
import gfx.live.events.ActionBarEvent;
import gfx.live.events.ChatboxEvent;
import gfx.live.events.GameboardEvent;
import gfx.live.events.PlyHistoryViewEvent;
import gfx.live.events.PositionEditorEvent;

interface IGameScreen extends INetObserver
{
    public function handleGameboardEvent(event:GameboardEvent):Void;
    public function handleChatboxEvent(event:ChatboxEvent):Void;
    public function handleActionBarEvent(event:ActionBarEvent):Void;
    public function handlePlyHistoryViewEvent(event:PlyHistoryViewEvent):Void;
    public function handleVariationViewEvent(event:VariationViewEvent):Void;
    public function handlePositionEditorEvent(event:PositionEditorEvent):Void;
}