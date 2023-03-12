package gfx.live.board.states;

import haxe.ui.events.MouseEvent;
import haxe.ui.geom.Point;
import net.shared.board.HexCoords;

interface IState
{
    private var boardInstance:GameBoard;
    public var cursorLocation(default, null):Null<HexCoords>;
    
    public function onEntered():Void;

    public function exit():Void;

    public function onLMBPressed(location:Null<HexCoords>, originalEvent:MouseEvent):Void;

    public function onMouseMoved(newCursorLocation:Null<HexCoords>, originalEvent:MouseEvent):Void;

    public function onLMBReleased(location:Null<HexCoords>, originalEvent:MouseEvent):Void;
}