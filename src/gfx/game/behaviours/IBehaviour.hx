package gfx.game.behaviours;

import net.shared.ServerEvent;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.events.PositionEditorEvent;
import gfx.game.events.VariationViewEvent;
import gfx.game.events.PlyHistoryViewEvent;
import gfx.game.events.ActionBarEvent;
import gfx.game.events.ChatboxEvent;
import gfx.game.events.GameboardEvent;

interface IBehaviour
{
    public function handleNetEvent(event:ServerEvent):Array<ModelUpdateEvent>;
    public function handleGameboardEvent(event:GameboardEvent):Array<ModelUpdateEvent>;
    public function handleChatboxEvent(event:ChatboxEvent):Array<ModelUpdateEvent>;
    public function handleActionBarEvent(event:ActionBarEvent):Array<ModelUpdateEvent>;
    public function handlePlyHistoryViewEvent(event:PlyHistoryViewEvent):Array<ModelUpdateEvent>;
    public function handleVariationViewEvent(event:VariationViewEvent):Array<ModelUpdateEvent>;
    public function handlePositionEditorEvent(event:PositionEditorEvent):Array<ModelUpdateEvent>;
}