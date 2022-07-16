package gameboard.states;

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
        if (equal(newCursorLocation, cursorLocation))
            return;
        
        if (newCursorLocation != null && boardInstance.plyHistory.isAtEnd() && !boardInstance.behavior.hoverDisabled() && reactsToHover(newCursorLocation))
            boardInstance.getHex(newCursorLocation).showLayer(Hover);

        if (cursorLocation != null)
            boardInstance.getHex(cursorLocation).hideLayer(Hover);

        cursorLocation = newCursorLocation;
    }

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