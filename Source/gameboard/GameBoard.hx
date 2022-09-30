package gameboard;

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
import openfl.geom.Point;
import struct.Variant;
import net.EventProcessingQueue.INetObserver;
import openfl.events.Event;
import struct.ReversiblePly;
import gfx.analysis.PosEditMode;
import struct.Hex;
import struct.IntPoint;
import struct.Ply;
import net.shared.ServerEvent;
import struct.PieceColor;
import gfx.utils.PlyScrollType;
import openfl.events.MouseEvent;
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

    public function revertOrientation()
    {
        setOrientation(opposite(orientationColor));
    }

    public function revertPlys(cnt:Int) 
    {
        if (cnt < 1)
            return;
        
        end();

        var toRevert:Array<ReversiblePly> = plyHistory.dropLast(cnt);
        _currentSituation.unmakeMoves(toRevert, true);
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
        removeLastMoveHighlighting();
    }   
    
    private function prev() 
    {
        var ply = plyHistory.prev(); 
        applyMoveTransposition(ply, true);
        highlightLastMove();
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
        highlightLastMove();
    }

    //=======================================================================================================

    private function onLMBPressed(e:MouseEvent)
    {
        if (suppressLMBHandler || Dialogs.hasActiveDialog())
            return;

        if (getBounds(stage).contains(e.stageX, e.stageY))
            state.onLMBPressed(posToIndexes(e.stageX, e.stageY), e.shiftKey, e.ctrlKey);
    }

    private function onMouseMoved(e:MouseEvent)
    {
        if (suppressLMBHandler || Dialogs.hasActiveDialog())
            return;

        state.onMouseMoved(posToIndexes(e.stageX, e.stageY));
        lastMouseMoveEvent = e;
    }

    private function onLMBReleased(e:MouseEvent)
    {
        if (suppressLMBHandler || Dialogs.hasActiveDialog())
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

    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event
        {
            case PreferenceUpdated(Markup):
                updateMarkup();
            case PreferenceUpdated(Premoves):
                behavior.onPremovePreferenceUpdated();
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

            case Live(New(whiteLogin, blackLogin, _, _, startingSituation, _)):
                this._startingSituation = startingSituation;
                this._currentSituation = _startingSituation.copy();
                
                var playerColor:PieceColor = LoginManager.isPlayer(whiteLogin)? White : Black;

                super(_startingSituation, Free, Free, playerColor);

                this.state = new NeutralState();
                this.behavior = _startingSituation.turnColor == playerColor? new PlayerMoveBehavior(playerColor) : new EnemyMoveBehavior(playerColor);

            case Live(Ongoing(parsedData, _, _, _, followedPlayerLogin)):
                this._startingSituation = parsedData.startingSituation.copy();
                this._currentSituation = _startingSituation.copy();

                var playerColor:PieceColor = parsedData.getPlayerColor();

                if (followedPlayerLogin == null)
                    super(_startingSituation, Free, Free, playerColor);
                else
                    super(_startingSituation, Free, Free, parsedData.getParticipantColor(followedPlayerLogin));
                
                for (ply in parsedData.movesPlayed)
                    makeMove(ply);

                if (followedPlayerLogin == null)
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
                    this.behavior = new StubBehavior();
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

        addEventListener(Event.ADDED_TO_STAGE, initLMB);
    }
}