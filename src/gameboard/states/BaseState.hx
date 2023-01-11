package gameboard.states;

import net.shared.board.HexCoords;
import gameboard.util.HexagonSelectionState;
import utils.exceptions.AlreadyInitializedException;
import net.shared.ServerEvent;

abstract class BaseState
{
    private var boardInstance:GameBoard;
    public var cursorLocation(default, null):Null<HexCoords>;
    
    private abstract function onEntered():Void;
    
    public abstract function exitToNeutral():Void;

    public abstract function onLMBPressed(location:Null<HexCoords>, shiftPressed:Bool, ctrlPressed:Bool):Void;

    private final function updateHoverEffects()
    {
        var hoverLayer:HexagonSelectionState = isHoverStrong()? StrongHover : PaleHover;
        
        if (cursorLocation != null)
            if (!boardInstance.behavior.hoverDisabled() && reactsToHover(cursorLocation))
                boardInstance.getHex(cursorLocation).showLayer(hoverLayer);
            else
                boardInstance.getHex(cursorLocation).hideLayer(hoverLayer);
    }

    public function onMouseMoved(newCursorLocation:Null<HexCoords>)
    {
        var hoverLayer:HexagonSelectionState = isHoverStrong()? StrongHover : PaleHover;

        if (equal(cursorLocation, newCursorLocation))
            return;
        
        if (newCursorLocation != null && !boardInstance.behavior.hoverDisabled() && reactsToHover(newCursorLocation))
            boardInstance.getHex(newCursorLocation).showLayer(hoverLayer);

        if (cursorLocation != null)
            boardInstance.getHex(cursorLocation).hideLayer(hoverLayer);

        cursorLocation = newCursorLocation;
    }

    private abstract function isHoverStrong():Bool;

    public abstract function reactsToHover(location:HexCoords):Bool;

    public abstract function onLMBReleased(location:Null<HexCoords>, shiftPressed:Bool, ctrlPressed:Bool):Void;

    public function init(board:GameBoard, ?cursorLocation:HexCoords)
    {
        if (boardInstance != null)
            throw new AlreadyInitializedException();
        this.boardInstance = board;
        this.cursorLocation = cursorLocation;
        this.onEntered();
        this.updateHoverEffects();
    }
}