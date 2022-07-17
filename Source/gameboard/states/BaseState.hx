package gameboard.states;

import gameboard.Hexagon.HexagonSelectionState;
import utils.exceptions.AlreadyInitializedException;
import struct.Hex;
import struct.IntPoint;
import net.ServerEvent;

abstract class BaseState
{
    private var boardInstance:GameBoard;
    public var cursorLocation(default, null):Null<IntPoint>;
    
    private abstract function onEntered():Void;
    
    public abstract function exitToNeutral():Void;

    public abstract function onLMBPressed(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool):Void;

    public final function onMouseMoved(newCursorLocation:Null<IntPoint>)
    {
        var hoverLayer:HexagonSelectionState = isHoverStrong()? StrongHover : PaleHover;

        if (equal(cursorLocation, newCursorLocation))
        {
            if (newCursorLocation != null)
                if (!boardInstance.behavior.hoverDisabled() && reactsToHover(newCursorLocation))
                    boardInstance.getHex(newCursorLocation).showLayer(hoverLayer);
                else
                    boardInstance.getHex(newCursorLocation).hideLayer(hoverLayer);
            return;
        }
        
        if (newCursorLocation != null && !boardInstance.behavior.hoverDisabled() && reactsToHover(newCursorLocation))
            boardInstance.getHex(newCursorLocation).showLayer(hoverLayer);

        if (cursorLocation != null)
            boardInstance.getHex(cursorLocation).hideLayer(hoverLayer);

        cursorLocation = newCursorLocation;
    }

    private abstract function isHoverStrong():Bool;

    public abstract function reactsToHover(location:IntPoint):Bool;

    public abstract function onLMBReleased(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool):Void;

    public function init(board:GameBoard, ?cursorLocation:IntPoint)
    {
        if (boardInstance != null)
            throw new AlreadyInitializedException();
        this.boardInstance = board;
        this.cursorLocation = cursorLocation;
        this.onEntered();
        this.onMouseMoved(cursorLocation);
    }
}