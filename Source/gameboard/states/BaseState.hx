package gameboard.states;

import struct.Hex;
import struct.IntPoint;
import net.ServerEvent;

class BaseState
{
    private var boardInstance:GameBoard;
    private var cursorLocation:Null<IntPoint>;

    public function onLMBPressed(location:Null<IntPoint>)
    {
        throw "Should be overriden";
    }

    public final function onMouseMoved(location:Null<IntPoint>)
    {
        var newCursorLocation = boardInstance.posToIndexes(location);

        if (equal(newCursorLocation, cursorLocation) || !boardInstance.plyHistory.isAtEnd())
            return;
        
        if (newCursorLocation != null && reactsToHover(newCursorLocation))
            boardInstance.getHex(newCursorLocation).showLayer(Hover);

        if (cursorLocation != null)
            boardInstance.getHex(cursorLocation).hideLayer(Hover);

        cursorLocation = newCursorLocation;
    }

    public function movePossible(from:IntPoint, to:IntPoint):Bool
    {
        throw "Should be overriden";
    }

    public function reactsToHover(location:IntPoint):Bool
    {
        throw "Should be overriden";
    }

    public function onLMBReleased(location:Null<IntPoint>)
    {
        throw "Should be overriden";
    }

    public function handleNetEvent(event:ServerEvent)
    {
        throw "Should be overriden";
    }

    public function new(board:GameBoard, ?cursorLocation:IntPoint)
    {
        this.boardInstance = board;
        this.cursorLocation = cursorLocation;
    }
}