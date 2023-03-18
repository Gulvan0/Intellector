package gfx.live.board;

import gfx.live.board.subcomponents.util.ArrowParams;
import gfx.live.board.util.HexSelectionMode;
import gfx.live.board.util.ArrowSelectionMode;
import Preferences.PreferenceName;
import gfx.live.board.util.HexagonLayer;
import gfx.live.board.util.Marking;
import gfx.live.board.states.IState;
import gfx.live.board.states.NeutralState;
import gfx.live.events.GameboardEvent;
import gfx.live.events.GlobalStateEvent;
import gfx.live.interfaces.IReadOnlyGlobalState;
import gfx.Dialogs;
import gfx.utils.Colors;
import haxe.ui.core.Screen;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.geom.Point;
import haxe.ui.util.Color;
import net.shared.PieceColor;
import net.shared.board.HexCoords;
import net.shared.board.RawPly;
import net.shared.board.Situation;

using Lambda;

class GameBoard extends SelectableBoard
{
    public var state(default, set):IState;
    public var mode:InteractivityMode;
    public var eventHandler:GameboardEvent->Void;
    public var globalStateRef:IReadOnlyGlobalState;

    public var lastMouseMoveEvent(default, null):MouseEvent;
    private var rmbPressLocation:Null<HexCoords>;

    private function set_state(newState:IState):IState
    {
        this.state = newState;
        newState.onEntered();
        return newState;
    }
    
    public override function resize(?e)
    {
        super.resize(e);
        if (lastMouseMoveEvent != null)
            onMouseMoved(lastMouseMoveEvent);
    }

    //=======================================================================================================

    private function onLMBPressed(e:MouseEvent)
    {
        if (Dialogs.getQueue().hasActiveDialog())
            return;

        if (e.screenX >= screenLeft && e.screenX <= screenLeft + width && e.screenY >= screenTop && e.screenY <= screenTop + height)
        {
            var pressCoords:Null<HexCoords> = posToIndexes(new Point(e.screenX - screenLeft, e.screenY - screenTop));
            state.onLMBPressed(pressCoords, e);
        }
    }

    private function onMouseMoved(e:MouseEvent)
    {
        lastMouseMoveEvent = e;
        
        if (Dialogs.getQueue().hasActiveDialog())
            return;

        state.onMouseMoved(posToIndexes(new Point(e.screenX - screenLeft, e.screenY - screenTop)), e);
    }

    private function onLMBReleased(e:MouseEvent)
    {
        if (Dialogs.getQueue().hasActiveDialog())
            return;

        state.onLMBReleased(posToIndexes(new Point(e.screenX - screenLeft, e.screenY - screenTop)), e);
    }

    @:bind(this, MouseEvent.RIGHT_MOUSE_DOWN)
    private function onRMBPressed(e:MouseEvent) 
    {
        if (Dialogs.getQueue().hasActiveDialog())
            return;

        rmbPressLocation = posToIndexes(new Point(e.screenX - screenLeft, e.screenY - screenTop));
    }

    @:bind(this, MouseEvent.RIGHT_MOUSE_UP)
    private function onRMBReleased(e:MouseEvent) 
    {
        if (Dialogs.getQueue().hasActiveDialog())
            return;

        var rmbReleaseLocation = posToIndexes(new Point(e.screenX - screenLeft, e.screenY - screenTop));

        if (rmbPressLocation != null && rmbReleaseLocation != null)
        {
            if (equal(rmbPressLocation, rmbReleaseLocation))
                toggleHexLayer(rmbPressLocation, HighlightedByPlayer);
            else
                toggleArrow(new ArrowParams(Colors.arrow, rmbPressLocation, rmbReleaseLocation));
        }
        
        rmbPressLocation = null;
    }

    @:bind(this, UIEvent.SHOWN)
    private function onAdded(e)
    {
        Screen.instance.registerEvent(MouseEvent.MOUSE_DOWN, onLMBPressed);
        Screen.instance.registerEvent(MouseEvent.MOUSE_MOVE, onMouseMoved);
        Screen.instance.registerEvent(MouseEvent.MOUSE_UP, onLMBReleased);
    }

    @:bind(this, UIEvent.HIDDEN)
    private function onRemoved(e)
    {
        Screen.instance.unregisterEvent(MouseEvent.MOUSE_DOWN, onLMBPressed);
        Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, onMouseMoved);
        Screen.instance.unregisterEvent(MouseEvent.MOUSE_UP, onLMBReleased);
    }

    public function handleGlobalStateEvent(event:GlobalStateEvent)
    {
        switch event 
        {
            case OrientationUpdated:
                setOrientation(globalStateRef.getOrientation());
            case ShownSituationUpdated:
                setShownSituation(globalStateRef.getShownSituation());
            case PlannedPremovesUpdated:
                var premoves:Array<RawPly> = globalStateRef.getPlannedPremoves();
                hideLayerForEveryHex(Premove);
                for (premove in premoves)
                    for (hexCoords in premove.modifiedHexes())
                        showHexLayer(hexCoords, Premove);
            case InteractivityModeUpdated:
                mode = globalStateRef.getBoardInteractivityMode();
            default:
                //* Do nothing
        }
    }

    public function onPreferenceUpdated(pref:PreferenceName) 
    {
        //TODO: React to changes in controls as well as diminishing arrows setting
        switch pref 
        {
            case Marking:
                updateMarking();
            default:
                //* Do nothing
        }
    }

    public function new(globalState:GlobalGameState, eventHandler:GameboardEvent->Void) 
    {
        var shownSituation:Situation = globalStateRef.getShownSituation();
        var arrowMode:Map<Color, ArrowSelectionMode> = [Colors.arrow => FreeConstSize]; //TODO: In the future, account for diminishing arrows & alt arrow colors
        var hexMode:Map<HexagonLayer, HexSelectionMode> = [
            HighlightedByPlayer => Free,
            LastMove => Free,
            Premove => Free,
            SelectedForMove => EnsureSingle,
            Hover => EnsureSingle
        ];
        var orientation:PieceColor = globalStateRef.getOrientation();
        var marking:Marking = Preferences.marking.get();

        super(shownSituation, arrowMode, hexMode, orientation, marking);

        this.state = new NeutralState(this, null);
        this.mode = globalStateRef.getBoardInteractivityMode();
        this.globalStateRef = globalState;
        this.eventHandler = eventHandler;
    }
}