package gfx.screens;

import gfx.components.SpriteWrapper;
import haxe.ui.containers.VBox;
import haxe.ui.containers.HBox;
import utils.TimeControl;
import gameboard.behaviors.PlayerMoveBehavior;
import gameboard.behaviors.EnemyMoveBehavior;
import gameboard.states.NeutralState;
import gameboard.states.StubState;
import net.LoginManager;
import struct.Situation;
import struct.PieceColor;
import openfl.Assets;
import net.GeneralObserver;
import net.ServerEvent;
import gfx.game.GameInfoBox;
import gfx.game.Chatbox;
import gfx.game.Sidebox;
import gameboard.GameBoard;
import gameboard.GameBoard.IGameBoardObserver;
import net.EventProcessingQueue.INetObserver;

class LiveGame extends Screen implements INetObserver implements IGameBoardObserver implements ISideboxObserver
{
    private var id:Int;

    private var board:GameBoard;
    private var sidebox:Sidebox;
    private var chatbox:Chatbox;
    private var gameinfobox:GameInfoBox;

    public override function onEntered()
    {
        GeneralObserver.acceptsDirectChallenges = false;
        //TODO: Fill
		Assets.getSound("sounds/notify.mp3").play();
    }

    public override function onClosed()
    {
        //TODO: Fill
        GeneralObserver.acceptsDirectChallenges = true;
    }

    public override function getURLPath():String
    {
        return 'live/$id';
    }

    public function handleNetEvent(event:ServerEvent)
    {
        //TODO: Fill
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        //TODO: Fill

        //TODO: Rewrite and insert
        /*
        field.onOwnMoveMade = (ply) -> {
            compound.makeMove(ply, Own);
            Networker.move(ply.from.i, ply.from.j, ply.to.i, ply.to.j, ply.morphInto);
        };
        */
    }

    public function handleSideboxEvent(event:SideboxEvent)
    {
        //TODO: Fill

        //TODO: Rewrite and insert
        /*
        function onResignPressed():

        var confirmed = Browser.window.confirm(resignConfirmationMessage);

		if (confirmed)
			Networker.emitEvent(Resign);
        */
        /*
        on RematchRequested:

        Networker.emitEvent(CreateDirectChallenge(opponentLogin, startSecs, secsPerTurn, playerIsWhite? "b" : "w"));
        */

        //TODO: Also check "color" param correctness for the above emitter ^
    }

    public function actualize(log:String, ?secondsLeftWhite:Int, ?secondsLeftBlack:Int)
    {
        //TODO: Fill
        //TODO: Set actual time for reconnect, spectation, revisit
        //TODO: Make sure either this is called with non-null optional arguments or correctTime() called right after actualize()
        //TODO: Maybe correctTime() should be forwarded to LiveGame interface
    }

    public function new(id:Int, whiteLogin:String, blackLogin:String, orientationColour:PieceColor, startSecs:Int, bonusSecs:Int, ?playerColor:PieceColor, ?turnColor:PieceColor = White)
    {
        super();
        this.id = id;

        board = new GameBoard(Situation.starting(), orientationColour);
        board.state = playerColor == null? new StubState(board) : new NeutralState(board);

        if (playerColor == null)
            board.behavior = new EnemyMoveBehavior(board, orientationColour); //Behavior doesn't matter at all, that's just a placeholder
        else if (turnColor == playerColor)
            board.behavior = new PlayerMoveBehavior(board, playerColor);
        else
            board.behavior = new EnemyMoveBehavior(board, playerColor);

        sidebox = new Sidebox(playerColor, startSecs, bonusSecs, whiteLogin, blackLogin, orientationColour);
        chatbox = new Chatbox(board.width * 0.45, board.height * 0.75, playerColor == null);
        gameinfobox = new GameInfoBox(board.width * 0.45, board.height * 0.23, new TimeControl(startSecs, bonusSecs), whiteLogin, blackLogin);

        var vbox:VBox = new VBox();
        vbox.addComponent(gameinfobox);
        vbox.addComponent(chatbox);

        var boardWrapper:SpriteWrapper = new SpriteWrapper();
        boardWrapper.sprite = board;

        var hbox:HBox = new HBox();
        hbox.addComponent(vbox);
        hbox.addComponent(boardWrapper);
        hbox.addComponent(vbox);

        addChild(hbox);
        
        //TODO: Connect children observers to corresponding observables
        sidebox.addObserver(this);
    }
}