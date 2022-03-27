package gameboard;

import openfl.geom.Point;
import struct.Variant;
import net.EventProcessingQueue.INetObserver;
import gfx.analysis.RightPanel.RightPanelObserver;
import openfl.events.Event;
import struct.ReversiblePly;
import gameboard.behaviors.AnalysisBehavior;
import gameboard.states.DirectSetState;
import gameboard.behaviors.EditorFreeMoveBehavior;
import gfx.analysis.PosEditMode;
import gameboard.states.NeutralState;
import gameboard.states.BasePlayableState;
import gfx.analysis.RightPanel.RightPanelEvent;
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
class GameBoard extends SelectableBoard implements RightPanelObserver implements INetObserver
{
    public var plyHistory:PlyHistory;
    public var currentSituation:Situation;

    public var state:BaseState;
    public var behavior:IBehavior;

    private var suppressLMBHandler:Bool = false;

    private var observers:Array<IGameBoardObserver> = [];
    
    public function startPieceDragging(location:IntPoint)
    {
        var piece:Piece = getPiece(location);
        pieceLayer.removeChild(piece);
        pieceLayer.addChild(piece);
        piece.startDrag(true);
    }

    public function applyScrolling(type:PlyScrollType) 
    {
        if ((type == Next || type == End) && plyHistory.isAtEnd())
            return;

        if (state.cursorLocation != null)
            getHex(state.cursorLocation).hideLayer(Hover);

        if (Std.isOfType(state, BasePlayableState))
            state.abortMove();

        if (plyHistory.isAtEnd() && (type == Prev || type == Home))
            behavior.onAboutToScrollAway();

        switch type 
        {
            case Home: home();
            case Prev: prev();
            case Next: next();
            case End: end();
        }
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
        var initialSituation:Situation = shownSituation.copy();
        var modifiedHexes:Array<IntPoint> = [];
        var seq:Array<ReversiblePly> = plyHistory.home(); 

        for (ply in seq)
            for (transform in ply)
                if (!modifiedHexes.exists(transform.coords.equals))
                {
                    initialSituation.set(transform.coords, transform.former.copy());
                    modifiedHexes.push(transform.coords);
                }
        
        setSituation(initialSituation);
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
                state = new NeutralState(this, state.cursorLocation);
                behavior = new EditorFreeMoveBehavior(this);
            case Delete:
                state = new DirectSetState(this, Hex.empty(), state.cursorLocation);
                behavior = new AnalysisBehavior(this, shownSituation.turnColor);
            case Set(type, color):
                state = new DirectSetState(this, Hex.occupied(type, color), state.cursorLocation);
                behavior = new AnalysisBehavior(this, shownSituation.turnColor);
        }
    }

    private function onLMBPressed(e:MouseEvent)
    {
        if (!suppressLMBHandler)
            if (getBounds(stage).contains(e.stageX, e.stageY))
                state.onLMBPressed(posToIndexes(e.stageX, e.stageY), e.shiftKey);
    }

    private function onMouseMoved(e:MouseEvent)
    {
        state.onMouseMoved(posToIndexes(e.stageX, e.stageY));
    }

    private function onLMBReleased(e:MouseEvent)
    {
        state.onLMBReleased(posToIndexes(e.stageX, e.stageY), e.shiftKey);
    }

    //TODO: Connect to Networker on creation (somewhere in OnlineGame screen)
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
    
    public function handleRightPanelEvent(event:RightPanelEvent)
    {
        switch event 
        {
            case BranchSelected(branch, startingSituation, pointer):
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
            case ConstructSituationRequested(situation):
                rearrangeToSituation(situation);
            case TurnColorChanged(newTurnColor):
                shownSituation.turnColor = newTurnColor;
            case ApplyChangesRequested:
                currentSituation = shownSituation.copy();
                plyHistory.clear();
                state = new NeutralState(this, state.cursorLocation);
                behavior = new AnalysisBehavior(this, currentSituation.turnColor);
                emit(SituationEdited(currentSituation));
            case DiscardChangesRequested:
                setSituation(currentSituation);
                state = new NeutralState(this, state.cursorLocation);
                behavior = new AnalysisBehavior(this, currentSituation.turnColor);
            case EditModeChanged(newEditMode):
                onEditModeChanged(newEditMode);
            case EditorEntered:
                removeArrowsAndSelections();
                highlightMove([]);
                onEditModeChanged(Move);
            case ScrollBtnPressed(type):
                applyScrolling(type);
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

    public function init(startState:BaseState, startBehavior:IBehavior)
    {
        this.state = startState;
        this.behavior = startBehavior;
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

    public function new(situation:Situation, orientationColor:PieceColor, hexSideLength:Float = 40) 
    {
        super(situation, orientationColor, hexSideLength, false);

        this.plyHistory = new PlyHistory();
        this.currentSituation = situation.copy();

        addEventListener(Event.ADDED_TO_STAGE, initLMB);
    }
}