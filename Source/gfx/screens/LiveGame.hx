package gfx.screens;

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

    public function new(id:Int, enemy:String, colour:PieceColor, startSecs:Int, bonusSecs:Int)
    {
        super();
        var playerIsWhite:Bool = data.colour == 'white';
        var whiteLogin = playerIsWhite? Networker.login : data.enemy;
        var blackLogin = playerIsWhite? data.enemy : Networker.login;
        
        board = new GameBoard(); //startingSituation, orientation
        board.state = //Depends on type
        sidebox = new Sidebox(false, data.startSecs, data.bonusSecs, Networker.login, data.enemy, data.colour == 'white');
        var chatbox:Chatbox = new Chatbox(field.getHeight() * 0.75);
        var infobox:GameInfoBox = new GameInfoBox(Chatbox.WIDTH, field.getHeight() * 0.23, data.startSecs, data.bonusSecs, whiteLogin, blackLogin);

        compound.playerColor = playerIsWhite? White : Black;
        sidebox.addObserver(this);
    }
}