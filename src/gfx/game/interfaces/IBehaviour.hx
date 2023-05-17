package gfx.game.interfaces;

import net.INetObserver;
import net.shared.ServerEvent;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.events.PositionEditorEvent;
import gfx.game.events.VariationViewEvent;
import gfx.game.events.PlyHistoryViewEvent;
import gfx.game.events.ActionBarEvent;
import gfx.game.events.ChatboxEvent;
import gfx.game.events.GameboardEvent;

interface IBehaviour extends INetObserver
{
    public function onEntered(modelUpdateHandler:ModelUpdateEvent->Void):Void;
    public function handleGameboardEvent(event:GameboardEvent):Void;
    public function handleChatboxEvent(event:ChatboxEvent):Void;
    public function handleActionBarEvent(event:ActionBarEvent):Void;
    public function handlePlyHistoryViewEvent(event:PlyHistoryViewEvent):Void;
    public function handleVariationViewEvent(event:VariationViewEvent):Void;
    public function handlePositionEditorEvent(event:PositionEditorEvent):Void;
}