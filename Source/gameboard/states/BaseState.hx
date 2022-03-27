package gameboard.states;

import struct.Hex;
import struct.IntPoint;
import net.ServerEvent;

class BaseState
{
    private var boardInstance:GameBoard;
    public var cursorLocation(default, null):Null<IntPoint>;
    
    public function abortMove()
    {
        throw "Should be overriden";
    }

    public function onLMBPressed(location:Null<IntPoint>, shiftPressed:Bool)
    {
        throw "Should be overriden";
    }

    public final function onMouseMoved(newCursorLocation:Null<IntPoint>)
    {
        if (equal(newCursorLocation, cursorLocation))
            return;
        
        if (newCursorLocation != null && boardInstance.plyHistory.isAtEnd() && !boardInstance.behavior.hoverDisabled() && reactsToHover(newCursorLocation))
            boardInstance.getHex(newCursorLocation).showLayer(Hover);

        if (cursorLocation != null)
            boardInstance.getHex(cursorLocation).hideLayer(Hover);

        cursorLocation = newCursorLocation;
    }

    public function reactsToHover(location:IntPoint):Bool
    {
        throw "Should be overriden";
    }

    public function onLMBReleased(location:Null<IntPoint>, shiftPressed:Bool)
    {
        throw "Should be overriden";
    }

    public function new(board:GameBoard, ?cursorLocation:IntPoint)
    {
        this.boardInstance = board;
        this.cursorLocation = cursorLocation;
    }
}