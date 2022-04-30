package tests.ui.board;

import struct.Situation;
import haxe.Timer;
import serialization.PlyDeserializer;
import struct.Ply;
import js.Browser;
import gameboard.behaviors.AnalysisBehavior;
import struct.PieceColor;
import gameboard.behaviors.EnemyMoveBehavior;
import gameboard.states.StubState;
import gameboard.behaviors.PlayerMoveBehavior;
import gameboard.states.NeutralState;
import gameboard.GameBoard;
import openfl.display.Sprite;

class TGameBoard extends Sprite
{
    private var board:GameBoard;

    private var playerColor:PieceColor;

    private function _act_setPlayerMoveBehavior()
    {
        board.behavior = new PlayerMoveBehavior(playerColor);
        board.plyHistory.clear();
    }

    private function _act_setEnemyMoveBehavior()
    {
        board.behavior = new EnemyMoveBehavior(playerColor);
        board.plyHistory.clear();
    }

    private function _act_setAnalysisBehavior()
    {
        board.behavior = new AnalysisBehavior(playerColor);
        board.plyHistory.clear();
    }

    private function _act_invertPlayerColor() 
    {
        playerColor = opposite(playerColor);
        if (Std.isOfType(board.behavior, PlayerMoveBehavior))
        {
            if (!Preferences.premoveEnabled.get())
                board.state = new StubState();
            board.behavior = new EnemyMoveBehavior(playerColor);
        }
        else if (Std.isOfType(board.behavior, EnemyMoveBehavior))
        {
            board.state = new NeutralState();
            board.behavior = new PlayerMoveBehavior(playerColor);
        }
        else if (Std.isOfType(board.behavior, AnalysisBehavior))
            board.behavior = new AnalysisBehavior(playerColor);
    }

    private function _act_enemyMove() 
    {
        var resp:String = Browser.window.prompt("Input the serialized ply", "");
        if (resp != "")
        {
            var ply:Ply = PlyDeserializer.deserialize(resp);
            board.handleNetEvent(Move(ply.from.i, ply.to.i, ply.from.j, ply.to.j, ply.morphInto == null? null : ply.morphInto.getName()));
        }
    }

    private function _act_rollback() 
    {
        var resp:String = Browser.window.prompt("Input the number of moves to cancel", "");
        if (resp != "")
        {
            board.handleNetEvent(Rollback(Std.parseInt(resp)));
        }
    }

    private function _act_endGame() 
    {
        var resp:String = Browser.window.prompt("Input the delay", "");
        if (resp != "")
        {
            Timer.delay(() -> {board.handleNetEvent(GameEnded('NONE', 'NONE'));}, Std.parseInt(resp));
        }
    }

    private function _act_togglePremoves() 
    {
        Preferences.premoveEnabled.set(!Preferences.premoveEnabled.get());
    }

    private function _act_printHistory() 
    {
        trace(Ply.plySequenceToNotation(board.plyHistory.getPlySequence(), Situation.starting()).join(" > "));
    }

    private function _act_home() 
    {
        board.applyScrolling(Home);
    }

    private function _act_prev() 
    {
        board.applyScrolling(Prev);
    }

    private function _act_next() 
    {
        board.applyScrolling(Next);
    }

    private function _act_end() 
    {
        board.applyScrolling(End);
    }

    private function _act_revertOrientation()
    {
        board.revertOrientation();
    }

    public function new() 
    {
        super();
        playerColor = White;

        board = new GameBoard(Situation.starting(), White, new EnemyMoveBehavior(playerColor), false, 50);
        addChild(board);
    } 
}