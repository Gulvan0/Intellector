package gameboard;

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

enum GameBoardEvent
{
    ContinuationMove(ply:RawPly, plyStr:String, performedBy:PieceColor);
    SubsequentMove(plyStr:String, performedBy:PieceColor);
    BranchingMove(ply:RawPly, plyStr:String, performedBy:PieceColor, droppedMovesCount:Int);
    ReturnedToCurrentPosition;
}

interface IGameBoardObserver
{
    public function handleGameBoardEvent(event:GameBoardEvent):Void;
}

/**
    SelectableBoard that allows scrolling through the game and emits various events
**/
@:allow(gameboard.behaviors.IBehavior)
@:allow(gameboard.states.BaseState)
class GameBoard extends SelectableBoard implements INetObserver implements IAnalysisPeripheralEventObserver implements IGlobalEventObserver
{
    public var plyHistory:PlyHistory;

    private var _currentSituation:Situation;
    public var currentSituation(get, never):Situation;

    private var _startingSituation:Situation;
    public var startingSituation(get, never):Situation;

    public var state(default, set):BaseState;
    public var behavior(default, set):IBehavior;

    public var suppressLMBHandler:Bool = false;
    private var lastMouseMoveEvent:MouseEvent;
    private var lastMousePress:{coords:Null<HexCoords>, ts:Float};

    private var observers:Array<IGameBoardObserver> = [];

    private function get_currentSituation():Situation
    {
        return _currentSituation.copy();
    }

    private function get_startingSituation():Situation
    {
        return _startingSituation.copy();
    }

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

    private function set_behavior(value:IBehavior):IBehavior 
    {
		try
        {
            value.init(this);
        }
        catch (e:AlreadyInitializedException)
        {
            throw new PosException("You can't assign already initialized behaviours to GameBoard", e);
        }
        return behavior = value;
    }
    
    public override function resize(?e)
    {
        super.resize(e);
        if (lastMouseMoveEvent != null)
            onMouseMoved(lastMouseMoveEvent);
    }

    public function revertOrientation()
    {
        setOrientation(opposite(orientationColor));
    }

    public function revertPlys(cnt:Int) 
    {
        if (cnt < 1)
            return;
        
        end();

        var toRevert:Array<MaterializedPly> = plyHistory.dropLast(cnt);
        toRevert.reverse();
        for (matPly in toRevert)
            _currentSituation.revertPly(matPly);
        setShownSituation(currentSituation);
        highlightLastMove();
    }

    public function revertToShown() 
    {
        if (plyHistory.isAtEnd())
            return;

        plyHistory.dropSinceShown();
        _currentSituation = shownSituation.copy();
    }

    private function removeLastMoveHighlighting()
    {
        highlightMove([]);
    }

    private function highlightLastMove()
    {
        if (plyHistory.isAtBeginning())
            removeLastMoveHighlighting();
        else
            highlightMove(plyHistory.getLastMove().affectedCoords());
    }

    /**
        Writes to history, updates currentSituation, highlights a move if a player hasn't browsed away.
        
        Except for premoves, transposes pieces accordingly
    **/
    public function makeMove(ply:RawPly)
    {
        var matPly:MaterializedPly = ply.toMaterialized(currentSituation);
        plyHistory.append(ply, matPly);
        _currentSituation.performPly(matPly);
        if (plyHistory.isAtEnd())
        {
            applyMoveTransposition(matPly);
            highlightMove([ply.from, ply.to]);
        }
    }

    public function applyScrolling(type:PlyScrollType) 
    {
        switch type 
        {
            case Home, Prev: 
                if (plyHistory.isAtBeginning())
                    return;
            case Next, End: 
                if (plyHistory.isAtEnd())
                    return;
            case Precise(plyNum):
                if (plyHistory.pointer == plyNum)
                    return;
        }

        state.exitToNeutral();

        if (plyHistory.isAtEnd())
            behavior.onAboutToScrollAway();

        switch type 
        {
            case Home: 
                home();
            case Prev: 
                prev();
            case Next: 
                next();
            case End: 
                end();
            case Precise(plyNum):
                while (plyHistory.pointer < plyNum)
                    next();
                while (plyHistory.pointer > plyNum)
                    prev();
        }
    }

    private function home()
    {
        plyHistory.home();
        setShownSituation(startingSituation);
        removeLastMoveHighlighting();
    }   
    
    private function prev() 
    {
        var matPly = plyHistory.prev(); 
        applyMoveTransposition(matPly, true);
        highlightLastMove();
    }

    public function next()
    {
        var matPly = plyHistory.next(); 
        applyMoveTransposition(matPly);
        highlightMove(matPly.affectedCoords());
    }

    private function end()
    {
        plyHistory.end(); 
        setShownSituation(currentSituation.copy());
        highlightLastMove();
    }

    //=======================================================================================================

    private function onLMBPressed(e:MouseEvent)
    {
        if (suppressLMBHandler || Dialogs.getQueue().hasActiveDialog())
            return;

        var eventTime:Float = Date.now().getTime();

        if (e.screenX >= screenLeft && e.screenX <= screenLeft + width && e.screenY >= screenTop && e.screenY <= screenTop + height)
        {
            var pressCoords:Null<HexCoords> = posToIndexes(toLocalCoords(e.screenX, e.screenY));

            if (lastMousePress == null || eventTime - lastMousePress.ts >= 750 || !equal(lastMousePress.coords, pressCoords))
                state.onLMBPressed(pressCoords, e.shiftKey, e.ctrlKey);

            lastMousePress = {ts: eventTime, coords: pressCoords};
        }
        else
            lastMousePress = {ts: eventTime, coords: null};
    }

    private function onMouseMoved(e:MouseEvent)
    {
        if (suppressLMBHandler || Dialogs.getQueue().hasActiveDialog())
            return;

        state.onMouseMoved(posToIndexes(toLocalCoords(e.screenX, e.screenY)));
        lastMouseMoveEvent = e;
    }

    private function onLMBReleased(e:MouseEvent)
    {
        if (suppressLMBHandler || Dialogs.getQueue().hasActiveDialog())
            return;

        state.onLMBReleased(posToIndexes(toLocalCoords(e.screenX, e.screenY)), e.shiftKey, e.ctrlKey);
    }

    public function handleNetEvent(event:ServerEvent)
    {
        behavior.handleNetEvent(event);
    }

    public function handleAnalysisPeripheralEvent(event:PeripheralEvent)
    {
        behavior.handleAnalysisPeripheralEvent(event);
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event
        {
            case PreferenceUpdated(Marking):
                updateMarking();
            case PreferenceUpdated(Premoves):
                behavior.onPremovePreferenceUpdated();
            default:
        }
    }

    public function addObserver(obs:IGameBoardObserver)
    {
        observers.push(obs);
    }

    public function emit(e:GameBoardEvent)
    {
        for (obs in observers)
            obs.handleGameBoardEvent(e);
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

    public function new(constructor:ComponentConstructor) 
    {
        this.plyHistory = new PlyHistory();

        switch constructor 
        {
            case Analysis(initialVariant):
                this._startingSituation = initialVariant.startingSituation.copy();
                this._currentSituation = _startingSituation.copy();

                super(_startingSituation, Free, Free, _startingSituation.turnColor);

                for (ply in initialVariant.getMainLineBranch())
                    makeMove(ply);

                this.state = new NeutralState();
                this.behavior = new AnalysisBehavior();

            case Live(New(whiteRef, blackRef, _, _, startingSituation, _)):
                this._startingSituation = startingSituation;
                this._currentSituation = _startingSituation.copy();
                
                var playerColor:PieceColor = LoginManager.isPlayer(whiteRef)? White : Black;

                super(_startingSituation, Free, Free, playerColor);

                this.state = _startingSituation.turnColor == playerColor || Preferences.premoveEnabled.get()? new NeutralState() : new StubState();
                this.behavior = _startingSituation.turnColor == playerColor? new PlayerMoveBehavior(playerColor) : new EnemyMoveBehavior(playerColor);

            case Live(Ongoing(parsedData, _, followedPlayerLogin)):
                this._startingSituation = parsedData.startingSituation.copy();
                this._currentSituation = _startingSituation.copy();

                var playerColor:Null<PieceColor> = parsedData.getPlayerColor();

                if (followedPlayerLogin != null)
                    super(_startingSituation, Free, Free, parsedData.getParticipantColor(followedPlayerLogin));
                else
                    super(_startingSituation, Free, Free, playerColor);
                
                for (ply in parsedData.movesPlayed)
                    makeMove(ply);

                if (parsedData.isPlayerParticipant())
                {
                    if (_currentSituation.turnColor == playerColor || Preferences.premoveEnabled.get())
                        this.state = new NeutralState();
                    else
                        this.state = new StubState();

                    this.behavior = _currentSituation.turnColor == playerColor? new PlayerMoveBehavior(playerColor) : new EnemyMoveBehavior(playerColor);
                }
                else
                {
                    this.state = new StubState();
                    this.behavior = new SpectatorBehavior();
                }

            
            case Live(Past(parsedData, watchedPlayerLogin)):
                this._startingSituation = parsedData.startingSituation.copy();
                this._currentSituation = _startingSituation.copy();

                super(_startingSituation, Free, Free, watchedPlayerLogin != null? parsedData.getParticipantColor(watchedPlayerLogin) : White);
                
                for (ply in parsedData.movesPlayed)
                    makeMove(ply);

                this.state = new StubState();
                this.behavior = new StubBehavior();

        }
    }
}