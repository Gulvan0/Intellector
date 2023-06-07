package gfx.game.board;

import gfx.game.interfaces.IGameScreenGetters;
import gfx.utils.SpecialControlSettings;
import gfx.game.events.ModelUpdateEvent;
import GlobalBroadcaster.GlobalEvent;
import GlobalBroadcaster.IGlobalEventObserver;
import gfx.game.interfaces.IBehaviour;
import gfx.game.models.ReadOnlyModel;
import gfx.game.board.subcomponents.util.ArrowParams;
import gfx.game.board.util.HexSelectionMode;
import gfx.game.board.util.ArrowSelectionMode;
import Preferences.PreferenceName;
import gfx.game.board.util.HexagonLayer;
import gfx.game.board.util.Marking;
import gfx.game.board.states.IState;
import gfx.game.board.states.NeutralState;
import gfx.game.events.GameboardEvent;
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
using gfx.game.models.CommonModelExtractors;

class GameBoard extends SelectableBoard implements IGlobalEventObserver
{
    public var state(default, set):IState;
    public var mode:InteractivityMode;
    public var eventHandler:GameboardEvent->Void;

    public var lastMouseMoveEvent(default, null):MouseEvent;
    private var rmbPressLocation:Null<HexCoords>;

    private var playerDrawnArrowColors:Array<Color>;

    private var getSpecialControlSettings:Void->SpecialControlSettings;

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
            var specialControlSettings:SpecialControlSettings = getSpecialControlSettings();

            switch specialControlSettings.lmbArrowDrawingMode 
            {
                case Disabled:
                    for (arrowColor in playerDrawnArrowColors)
                        removeAllArrows(arrowColor);
        
                    var pressCoords:Null<HexCoords> = posToIndexes(new Point(e.screenX - screenLeft, e.screenY - screenTop));
                    state.onLMBPressed(pressCoords, e, specialControlSettings);
                default:
                    handlePressAsPlayerHighlighting(e);
            }
        }
    }

    private function onMouseMoved(e:MouseEvent)
    {
        lastMouseMoveEvent = e;
        
        if (Dialogs.getQueue().hasActiveDialog())
            return;

        var moveCoords:Null<HexCoords> = posToIndexes(new Point(e.screenX - screenLeft, e.screenY - screenTop));
        state.onMouseMoved(moveCoords, e);
    }

    private function onLMBReleased(e:MouseEvent)
    {
        if (Dialogs.getQueue().hasActiveDialog())
            return;

        var specialControlSettings:SpecialControlSettings = getSpecialControlSettings();

        switch specialControlSettings.lmbArrowDrawingMode 
        {
            case Disabled:
                var releaseCoords:Null<HexCoords> = posToIndexes(new Point(e.screenX - screenLeft, e.screenY - screenTop));
                state.onLMBReleased(releaseCoords, e, specialControlSettings);
            case Red:
                handleReleaseAsPlayerHighlighting(e, Colors.playerDrawnArrowNormal);
            case Green:
                handleReleaseAsPlayerHighlighting(e, Colors.playerDrawnArrowGreen);
            case Blue:
                handleReleaseAsPlayerHighlighting(e, Colors.playerDrawnArrowBlue);
            case Black:
                handleReleaseAsPlayerHighlighting(e, Colors.playerDrawnArrowBlack);
        }
    }

    @:bind(this, MouseEvent.RIGHT_MOUSE_DOWN)
    private function onRMBPressed(e:MouseEvent) 
    {
        if (Dialogs.getQueue().hasActiveDialog())
            return;

        handlePressAsPlayerHighlighting(e);
    }

    @:bind(this, MouseEvent.RIGHT_MOUSE_UP)
    private function onRMBReleased(e:MouseEvent) 
    {
        if (Dialogs.getQueue().hasActiveDialog())
            return;

        handleReleaseAsPlayerHighlighting(e);
    }

    private function handlePressAsPlayerHighlighting(e:MouseEvent) 
    {
        rmbPressLocation = posToIndexes(new Point(e.screenX - screenLeft, e.screenY - screenTop));
    }

    private function handleReleaseAsPlayerHighlighting(e:MouseEvent, ?forcedArrowColor:Color) 
    {
        var rmbReleaseLocation = posToIndexes(new Point(e.screenX - screenLeft, e.screenY - screenTop));

        if (rmbPressLocation != null && rmbReleaseLocation != null)
        {
            if (equal(rmbPressLocation, rmbReleaseLocation))
                toggleHexLayer(rmbPressLocation, HighlightedByPlayer);
            else
            {
                var arrowColor:Color;
                if (forcedArrowColor != null)
                    arrowColor = forcedArrowColor;
                else if (e.shiftKey && e.ctrlKey)
                    arrowColor = Colors.playerDrawnArrowBlack;
                else if (e.ctrlKey)
                    arrowColor = Colors.playerDrawnArrowBlue;
                else if (e.shiftKey)
                    arrowColor = Colors.playerDrawnArrowGreen;
                else
                    arrowColor = Colors.playerDrawnArrowNormal;

                toggleArrow(new ArrowParams(arrowColor, rmbPressLocation, rmbReleaseLocation));
            }
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

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent)
    {
        switch event 
        {
            case OrientationUpdated:
                setOrientation(model.asGenericModel().getOrientation());
            case ShownSituationUpdated:
                var newSituation:Situation = model.asGenericModel().getShownSituation();

                if (newSituation.equals(shownSituation))
                    return;

                removeAllArrows();
                setShownSituation(newSituation);
            case InteractivityModeUpdated:
                mode = model.asGenericModel().getBoardInteractivityMode();
            case PlannedPremovesUpdated:
                hideLayerForEveryHex(Premove);
                for (premove in model.getPlannedPremoves())
                    for (hexCoords in premove.modifiedHexes())
                        showHexLayer(hexCoords, Premove);
            default:
        }
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case PreferenceUpdated(Marking):
                updateMarking();
            default:
        }
    }

    public function new(model:ReadOnlyModel, getters:IGameScreenGetters) 
    {
        var shownSituation:Situation = model.asGenericModel().getShownSituation();
        var orientation:PieceColor = model.asGenericModel().getOrientation();
        var mode:InteractivityMode = model.asGenericModel().getBoardInteractivityMode();

        var playerDrawnArrowColors:Array<Color> = [Colors.playerDrawnArrowNormal, Colors.playerDrawnArrowGreen, Colors.playerDrawnArrowBlue, Colors.playerDrawnArrowBlack];

        var arrowMode:Map<Color, ArrowSelectionMode> = [for (arrowColor in playerDrawnArrowColors) arrowColor => FreeConstSize];
        var hexMode:Map<HexagonLayer, HexSelectionMode> = [
            HighlightedByPlayer => Free,
            LastMove => Free,
            Premove => Free,
            SelectedForMove => EnsureSingle,
            Hover => EnsureSingle
        ];
        var marking:Marking = Preferences.marking.get();

        super(shownSituation, arrowMode, hexMode, orientation, marking);

        this.state = new NeutralState(this, null);
        this.mode = mode;
        this.eventHandler = getters.getBehaviour().handleGameboardEvent;
        this.getSpecialControlSettings = getters.getSpecialControlSettings;

        this.playerDrawnArrowColors = playerDrawnArrowColors;
    }
}