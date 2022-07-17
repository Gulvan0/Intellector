package gameboard;

import gfx.analysis.PeripheralEvent;
import gameboard.states.StubState;
import haxe.exceptions.PosException;
import utils.exceptions.AlreadyInitializedException;
import openfl.geom.Point;
import struct.Variant;
import net.EventProcessingQueue.INetObserver;
import openfl.events.Event;
import struct.ReversiblePly;
import gameboard.behaviors.AnalysisBehavior;
import gameboard.states.HexSelectionState;
import gameboard.behaviors.EditorFreeMoveBehavior;
import gfx.analysis.PosEditMode;
import gameboard.states.NeutralState;
import gameboard.states.BasePlayableState;
import struct.Hex;
import gameboard.behaviors.IBehavior;
import struct.IntPoint;
import struct.Ply;
import net.ServerEvent;
import struct.PieceColor;
import gfx.utils.PlyScrollType;
import openfl.events.MouseEvent;
import gameboard.states.BaseState;
import struct.Situation;
using Lambda;

enum GameBoardEvent
{
    ContinuationMove(ply:Ply, plyStr:String, performedBy:PieceColor);
    SubsequentMove(plyStr:String, performedBy:PieceColor);
    BranchingMove(ply:Ply, plyStr:String, performedBy:PieceColor, droppedMovesCount:Int);
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
class GameBoard extends SelectableBoard implements INetObserver
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
    
    public override function resize(newHexSideLength:Float)
    {
        super.resize(newHexSideLength);
        if (lastMouseMoveEvent != null)
            onMouseMoved(lastMouseMoveEvent);
    }

    public function bringPieceToFront(piece:Piece)
    {
        if (piece.parent != null)
            pieceLayer.addChild(piece);
    }

    public function revertPlys(cnt:Int) 
    {
        if (cnt < 1)
            return;
        
        end();

        var toRevert:Array<ReversiblePly> = plyHistory.dropLast(cnt);
        _currentSituation.unmakeMoves(toRevert, true);
        setShownSituation(currentSituation);
        highlightMove(plyHistory.getLastMove().affectedCoords());
    }

    public function revertToShown() 
    {
        if (plyHistory.isAtEnd())
            return;

        plyHistory.dropSinceShown();
        _currentSituation = shownSituation.copy();
    }

    /**
        Writes to history, updates currentSituation, highlights a move if a player hasn't browsed away.
        
        Except for premoves, transposes pieces accordingly
    **/
    public function makeMove(ply:Ply)
    {
        var revPly:ReversiblePly = ply.toReversible(currentSituation);
        plyHistory.append(ply, revPly);
        _currentSituation.makeMove(ply, true);
        if (plyHistory.isAtEnd())
        {
            applyMoveTransposition(revPly);
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
        highlightMove([]);
    }   
    
    private function prev() 
    {
        var ply = plyHistory.prev(); 
        applyMoveTransposition(ply, true);
        if (plyHistory.isAtBeginning())
            highlightMove([]);
        else
            highlightMove(plyHistory.getLastMove().affectedCoords());
    }

    public function next()
    {
        var ply = plyHistory.next(); 
        applyMoveTransposition(ply);
        highlightMove(ply.affectedCoords());
    }

    private function end()
    {
        plyHistory.end(); 
        setShownSituation(currentSituation.copy());
        highlightMove(plyHistory.getLastMove().affectedCoords());
    }

    //=======================================================================================================

    private function onLMBPressed(e:MouseEvent)
    {
        if (suppressLMBHandler)
            return;

        if (getBounds(stage).contains(e.stageX, e.stageY))
            state.onLMBPressed(posToIndexes(e.stageX, e.stageY), e.shiftKey, e.ctrlKey);
    }

    private function onMouseMoved(e:MouseEvent)
    {
        if (suppressLMBHandler)
            return;

        state.onMouseMoved(posToIndexes(e.stageX, e.stageY));
        lastMouseMoveEvent = e;
    }

    private function onLMBReleased(e:MouseEvent)
    {
        if (suppressLMBHandler)
            return;

        state.onLMBReleased(posToIndexes(e.stageX, e.stageY), e.shiftKey, e.ctrlKey);
    }

    public function handleNetEvent(event:ServerEvent)
    {
        behavior.handleNetEvent(event);
    }

    public function handleAnalysisPeripheralEvent(event:PeripheralEvent)
    {
        behavior.handleAnalysisPeripheralEvent(event);
    }

    private function initLMB(e)
    {
        removeEventListener(Event.ADDED_TO_STAGE, initLMB);
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onLMBPressed);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoved);
        stage.addEventListener(MouseEvent.MOUSE_UP, onLMBReleased);
        addEventListener(Event.REMOVED_FROM_STAGE, terminateLMB);
    }

    private function terminateLMB(e)
    {
        removeEventListener(Event.REMOVED_FROM_STAGE, terminateLMB);
        stage.removeEventListener(MouseEvent.MOUSE_DOWN, onLMBPressed);
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoved);
        stage.removeEventListener(MouseEvent.MOUSE_UP, onLMBReleased);
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

    public function new(situation:Situation, orientationColor:PieceColor, startBehavior:IBehavior, stubState:Bool = false, hexSideLength:Float = 40) 
    {
        super(situation, Free, Free, orientationColor, hexSideLength);

        this.plyHistory = new PlyHistory();
        this._currentSituation = situation.copy();
        this._startingSituation = situation.copy();
        this.state = stubState? new StubState() : new NeutralState();
        this.behavior = startBehavior;

        addEventListener(Event.ADDED_TO_STAGE, initLMB);
    }
}