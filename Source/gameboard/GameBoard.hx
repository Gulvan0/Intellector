package gameboard;

import struct.IntPoint;
import struct.Ply;
import net.ServerEvent;
import gameboard.states.PlayerMoveNeutralState;
import struct.PieceColor;
import gfx.utils.PlyScrollType;
import openfl.events.MouseEvent;
import gameboard.states.BaseState;
import struct.Situation;

enum GameBoardEvent //TODO: Emit in all states
{
    ContinuationMove(plyStr:String, performedBy:PieceColor);
    SubsequentMove(plyStr:String, performedBy:PieceColor);
    BranchingMove(plyStr:String, performedBy:PieceColor);
    //TODO: add events for edit-type states
}

interface IGameBoardObserver
{
    public function handleGameBoardEvent(e:GameBoardEvent):Void;
}

/**
    SelectableBoard that allows scrolling through the game and emits various events

    Changes behaviour based on the current state
**/
class GameBoard extends SelectableBoard
{
    public var plyHistory:PlyHistory;
    public var currentSituation:Situation;
    public var state:BaseState;

    private var suppressLMBHandler:Bool = false;

    private var observers:Array<IGameBoardObserver> = [];
    
    public function startPieceDragging(location:IntPoint)
    {
        var piece:Piece = getPiece(location);
        removeChild(piece);
        addChild(piece);
        piece.startDrag(true);
    }

    public function applyScrolling(type:PlyScrollType) 
    {
        if ((type == Next || type == End) && plyHistory.isAtEnd())
            return;

        if (state.cursorLocation != null)
            getHex(state.cursorLocation).hideLayer(Hover);
        if (Std.isOfType(state, PlayerMoveSelectedState))
        {
            getHex(cast(state, PlayerMoveSelectedState).selectedDepartureLocation).hideLayer(LMB);
            state = new PlayerMoveNeutralState(this, state.cursorLocation);
        }

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
        piece.x = origPosition.x;
        piece.y = origPosition.y;
    }

    /**
        Writes to history, updates currentSituation, highlights a move if a player hasn't browsed away.
        
        Except for premoves, transposes pieces accordingly
    **/
    public function makeMove(ply:Ply, ?triggeredByPremove:Bool = false)
    {
        var revPly:ReversiblePly = ply.toReversible();
        plyHistory.append(revPly);
        currentSituation = currentSituation.makeMove(ply);
        if (plyHistory.isAtEnd())
        {
            if (!triggeredByPremove)
                applyMoveTransposition(revPly);
            highlightMove([ply.from, ply.to]);
        }
    }

    private function home()
    {
        var initalSituation:Situation = shownSituation.copy();
        var modifiedHexes:Array<IntPoint> = [];
        var seq:Array<ReversiblePly> = plyHistory.home(); 

        for (ply in seq)
            for (transform in ply)
                if (!modifiedHexes.has(transform.coords.equals))
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
        highlightMove(ply.affectedCoords());
    }

    private function next()
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

    private function onLMBPressed(e:MouseEvent)
    {
        if (!suppressLMBHandler)
            state.onLMBPressed(posToIndexes(e.stageX - x, e.stageY - y));
    }

    private function onMouseMoved(e:MouseEvent)
    {
        state.onMouseMoved(posToIndexes(e.stageX - x, e.stageY - y));
    }

    private function onLMBReleased(e:MouseEvent)
    {
        state.onLMBReleased(posToIndexes(e.stageX - x, e.stageY - y));
    }

    public function handleNetEvent(event:ServerEvent)
    {
        state.handleNetEvent(event);
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

    private function addObserver(obs:IGameBoardObserver)
    {
        observers.push(obs);
    }

    public function emit(e:GameBoardEvent)
    {
        for (obs in observers)
            obs.handleGameBoardEvent(e);
    }

    public function new(situation:Situation, playerColor:PieceColor, startState:BaseState, ?orientationColor:PieceColor, hexSideLength:Float = 40) 
    {
        super(situation, orientationColor == null? playerColor : orientationColor, hexSideLength, false);

        this.plyHistory = new PlyHistory();
        this.currentSituation = situation.copy();
        this.state = startState;

        addEventListener(Event.ADDED_TO_STAGE, initLMB);
    }    
}