package gfx.game.interfaces;

import net.INetObserver;
import gfx.game.events.VariationViewEvent;
import gfx.game.events.ActionBarEvent;
import gfx.game.events.ChatboxEvent;
import gfx.game.events.GameboardEvent;
import gfx.game.events.PlyHistoryViewEvent;
import gfx.game.events.PositionEditorEvent;

interface IGameScreen extends INetObserver
{
    public function handleGameboardEvent(event:GameboardEvent):Void;
    public function handleChatboxEvent(event:ChatboxEvent):Void;
    public function handleActionBarEvent(event:ActionBarEvent):Void;
    public function handlePlyHistoryViewEvent(event:PlyHistoryViewEvent):Void;
    public function handleVariationViewEvent(event:VariationViewEvent):Void;
    public function handlePositionEditorEvent(event:PositionEditorEvent):Void;
}