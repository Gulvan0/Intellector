package gameboard_revamped;

import gameboard_revamped.events.GameboardEvent;
import haxe.ui.geom.Point;
import net.shared.board.HexCoords;
import net.shared.board.HexCoords.equal;
import gameboard.util.HexDimensions;
import gameboard.components.Piece;
import haxe.ui.core.Screen;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import net.shared.board.MaterializedPly;
import net.shared.board.RawPly;
import net.shared.board.Situation;
import gameboard.behaviors.SpectatorBehaviour;
import GlobalBroadcaster;
import GlobalBroadcaster.IGlobalEventObserver;
import gameboard.behaviors.*;
import gameboard.states.*;
import gfx.common.ComponentConstructor;
import gfx.game.LiveGameConstructor;
import gfx.analysis.IAnalysisPeripheralEventObserver;
import gfx.Dialogs;
import gfx.analysis.PeripheralEvent;
import haxe.exceptions.PosException;
import utils.exceptions.AlreadyInitializedException;
import struct.Variant;
import net.EventProcessingQueue.INetObserver;
import gfx.analysis.PosEditMode;
import net.shared.ServerEvent;
import net.shared.PieceColor;
import gfx.utils.PlyScrollType;
using Lambda;

@:allow(gameboard.states.BaseState)
class GameBoard extends SelectableBoard
{
    public var state(default, set):BaseState;
    public var mode:InteractivityMode;
    public var eventHandler:GameboardEvent;

    private var lastMouseMoveEvent:MouseEvent;
    private var lastMousePress:{coords:Null<HexCoords>, ts:Float};

    private function set_state(value:BaseState):BaseState 
    {
        try
        {
            if (state != null)
                value.init(this, state.cursorLocation);
            else
                value.init(this);
        }
        catch (e:AlreadyInitializedException)
        {
            throw new PosException("You can't assign already initialized states to GameBoard", e);
        }
        return state = value;
	}
    
    public override function resize(?e)
    {
        super.resize(e);
        if (lastMouseMoveEvent != null)
            onMouseMoved(lastMouseMoveEvent);
    }

    //=======================================================================================================

    private function onLMBPressed(e:MouseEvent) //TODO: Refer to InteractivityMode
    {
        if (Dialogs.getQueue().hasActiveDialog())
            return;

        var eventTime:Float = Date.now().getTime();

        if (e.screenX >= screenLeft && e.screenX <= screenLeft + width && e.screenY >= screenTop && e.screenY <= screenTop + height)
        {
            var pressCoords:Null<HexCoords> = posToIndexes(toLocalCoords(e.screenX, e.screenY));

            if (lastMousePress == null || eventTime - lastMousePress.ts >= 750 || !equal(lastMousePress.coords, pressCoords))
                state.onLMBPressed(pressCoords, new Point(e.screenX, e.screenY), e.shiftKey, e.ctrlKey);

            lastMousePress = {ts: eventTime, coords: pressCoords};
        }
        else
            lastMousePress = {ts: eventTime, coords: null};
    }

    private function onMouseMoved(e:MouseEvent) //TODO: Refer to InteractivityMode
    {
        lastMouseMoveEvent = e;
        
        if (Dialogs.getQueue().hasActiveDialog())
            return;

        state.onMouseMoved(posToIndexes(toLocalCoords(e.screenX, e.screenY)));
    }

    private function onLMBReleased(e:MouseEvent) //TODO: Refer to InteractivityMode
    {
        if (Dialogs.getQueue().hasActiveDialog())
            return;

        state.onLMBReleased(posToIndexes(toLocalCoords(e.screenX, e.screenY)), e.shiftKey, e.ctrlKey);
    }

    @:bind(this, UIEvent.SHOWN)
    private function onAddedGB(e)
    {
        Screen.instance.registerEvent(MouseEvent.MOUSE_DOWN, onLMBPressed);
        Screen.instance.registerEvent(MouseEvent.MOUSE_MOVE, onMouseMoved);
        Screen.instance.registerEvent(MouseEvent.MOUSE_UP, onLMBReleased);
    }

    @:bind(this, UIEvent.HIDDEN)
    private function onRemovedGB(e)
    {
        Screen.instance.unregisterEvent(MouseEvent.MOUSE_DOWN, onLMBPressed);
        Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, onMouseMoved);
        Screen.instance.unregisterEvent(MouseEvent.MOUSE_UP, onLMBReleased);
    }

    public function new() 
    {
        //TODO: Add arguments and call super
    }
}