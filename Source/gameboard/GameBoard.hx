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
import gameboard.states.DirectSetState;
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
    BranchingMove(ply:Ply, plyStr:String, performedBy:PieceColor, plyPointer:Int, branchLength:Int);
    SituationEdited(newSituation:Situation);
}

interface IGameBoardObserver
{
    public function handleGameBoardEvent(event:GameBoardEvent):Void;
}

/**
    SelectableBoard that allows scrolling through the game and emits various events

    Changes behaviour based on the current state
**/
class GameBoard extends SelectableBoard implements INetObserver
{
    public var plyHistory:PlyHistory;
    public var currentSituation:Situation;
    private var startingSituation:Situation;

    public var state(default, set):BaseState;
    public var behavior(default, set):IBehavior;

    public var suppressLMBHandler:Bool = false;
    private var lastMouseMoveEvent:MouseEvent;

    private var observers:Array<IGameBoardObserver> = [];

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

    public function startPieceDragging(location:IntPoint)
    {
        var piece:Piece = getPiece(location);
        pieceLayer.removeChild(piece);
        pieceLayer.addChild(piece);
        piece.startDrag(true);
    }

    private function prepareToScrollAway()
    {
        if (state.cursorLocation != null)
            getHex(state.cursorLocation).hideLayer(Hover);

        if (Std.isOfType(state, BasePlayableState))
            state.abortMove();

        if (plyHistory.isAtEnd())
            behavior.onAboutToScrollAway();
    }

    public function applyScrolling(type:PlyScrollType) 
    {
        if ((type == Next || type == End) && plyHistory.isAtEnd())
            return;
        else if ((type == Prev || type == Home) && plyHistory.isAtBeginning())
            return;

        prepareToScrollAway();

        switch type 
        {
            case Home: home();
            case Prev: prev();
            case Next: next();
            case End: end();
        }
    }

    public function scrollToMove(moveNum:Int)
    {
        if (plyHistory.pointer == moveNum)
            return;

        prepareToScrollAway();

        while (plyHistory.pointer < moveNum)
            next();

        while (plyHistory.pointer > moveNum)
            prev();
    }

    public function revertPlys(cnt:Int) 
    {
        if (cnt < 1)
            return;
        
        end();

        var toRevert:Array<ReversiblePly> = plyHistory.dropLast(cnt);
        currentSituation = currentSituation.unmakeMoves(toRevert);
        setSituation(currentSituation);
        highlightMove(plyHistory.getLastMove().affectedCoords());
    }

    public function revertToShown() 
    {
        if (plyHistory.isAtEnd())
            return;

        plyHistory.dropSinceShown();
        currentSituation = shownSituation.copy();
    }

    public function returnPieceToOriginalPosition(pieceOriginalLocation:IntPoint)
    {
        var piece = getPiece(pieceOriginalLocation);
        var origPosition = hexCoords(pieceOriginalLocation);
        piece.dispose(origPosition);
    }

    /**
        Writes to history, updates currentSituation, highlights a move if a player hasn't browsed away.
        
        Except for premoves, transposes pieces accordingly
    **/
    public function makeMove(ply:Ply)
    {
        var revPly:ReversiblePly = ply.toReversible(currentSituation);
        plyHistory.append(ply, revPly);
        currentSituation = currentSituation.makeMove(ply);
        if (plyHistory.isAtEnd())
        {
            applyMoveTransposition(revPly);
            highlightMove([ply.from, ply.to]);
        }
    }

    /**For editor usage only**/
    public function teleportPiece(from:IntPoint, to:IntPoint)
    {
        if (!shownSituation.get(to).isEmpty())
            removeChild(getPiece(to));
                
        getPiece(from).dispose(hexCoords(to));
        shownSituation.set(to, shownSituation.get(from));
        shownSituation.set(from, Hex.empty());
    }

    private function home()
    {
        plyHistory.home();
        setSituation(startingSituation);
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
        setSituation(currentSituation.copy());
        highlightMove(plyHistory.getLastMove().affectedCoords());
    } 

    private function onEditModeChanged(newEditMode:PosEditMode)
    {
        state.abortMove();

        switch newEditMode 
        {
            case Move:
                state = new NeutralState();
                behavior = new EditorFreeMoveBehavior();
            case Delete:
                state = new DirectSetState(Hex.empty());
                behavior = new AnalysisBehavior(shownSituation.turnColor);
            case Set(type, color):
                state = new DirectSetState(Hex.occupied(type, color));
                behavior = new AnalysisBehavior(shownSituation.turnColor);
        }
    }

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

    private function rearrangeToSituation(situation:Situation)
    {
        removeArrowsAndSelections();
        highlightMove([]);
        setSituation(situation.copy());
    }
    
    public function handleAnalysisPeripheralEvent(event:PeripheralEvent)
    {
        switch event 
        {
            case BranchSelected(branch, branchStr, pointer):
                var situation = startingSituation.copy();
                var i = 0;
                plyHistory.clear();
                for (ply in branch)
                {
                    plyHistory.append(ply, ply.toReversible(situation));
                    situation = situation.makeMove(ply);
                    if (i == pointer)
                        rearrangeToSituation(situation);
                    i++;
                }
            case RevertNeeded(plyCnt):
                revertPlys(plyCnt);
            case ClearRequested:
                rearrangeToSituation(Situation.empty());
            case ResetRequested:
                rearrangeToSituation(currentSituation);
            case StartPosRequested:
                rearrangeToSituation(Situation.starting());
            case OrientationChangeRequested:
                revertOrientation();
            case ConstructSituationRequested(situation):
                rearrangeToSituation(situation);
            case TurnColorChanged(newTurnColor):
                shownSituation.turnColor = newTurnColor;
            case ApplyChangesRequested(turnColor):
                currentSituation = shownSituation.copy();
                plyHistory.clear();
                state = new NeutralState();
                behavior = new AnalysisBehavior(currentSituation.turnColor);
                emit(SituationEdited(currentSituation));
            case DiscardChangesRequested:
                setSituation(currentSituation);
                state = new NeutralState();
                behavior = new AnalysisBehavior(currentSituation.turnColor);
            case EditModeChanged(newEditMode):
                onEditModeChanged(newEditMode);
            case EditorLaunchRequested:
                removeArrowsAndSelections();
                highlightMove([]);
                onEditModeChanged(Move);
            case ScrollBtnPressed(type):
                applyScrolling(type);
            case PlySelected(index):
                scrollToMove(index);
            default:
        }
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

    public function asVariant():Null<Variant> 
    {
        var situation:Situation = Situation.starting();
        var variant:Variant = new Variant(situation);

        var path:Array<Int> = [];
        for (ply in plyHistory.getPlySequence())
        {
            variant.addChildToNode(ply, path);
            path.push(0);
        }

        return variant;
	}

    public function new(situation:Situation, orientationColor:PieceColor, startBehavior:IBehavior, stubState:Bool = false, hexSideLength:Float = 40) 
    {
        super(situation, Free, Free, orientationColor, hexSideLength, false);

        this.plyHistory = new PlyHistory();
        this.currentSituation = situation.copy();
        this.startingSituation = situation.copy();
        this.state = stubState? new StubState() : new NeutralState();
        this.behavior = startBehavior;

        addEventListener(Event.ADDED_TO_STAGE, initLMB);
    }
}