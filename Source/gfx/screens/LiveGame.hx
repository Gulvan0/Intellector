package gfx.screens;

import dict.Dictionary;
import js.Browser;
import struct.IntPoint;
import struct.Ply;
import serialization.GameLogParser;
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
    private var viewingAsParticipatingPlayer:Bool;

    private var board:GameBoard;
    private var sidebox:Sidebox;
    private var chatbox:Chatbox;
    private var gameinfobox:GameInfoBox;

    public override function onEntered()
    {
        GeneralObserver.acceptsDirectChallenges = false;
        Networker.eventQueue.addObserver(gameinfobox);
        Networker.eventQueue.addObserver(chatbox);
        Networker.eventQueue.addObserver(sidebox);
		Assets.getSound("sounds/notify.mp3").play();
    }

    public override function onClosed()
    {
        Networker.eventQueue.removeObserser(gameinfobox);
        Networker.eventQueue.removeObserser(chatbox);
        Networker.eventQueue.removeObserser(sidebox);
        GeneralObserver.acceptsDirectChallenges = true;
    }

    public override function getURLPath():String
    {
        return 'live/$id';
    }

    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case Move(fromI, toI, fromJ, toJ, morphInto):
                var ply:Ply = Ply.construct(new IntPoint(fromI, fromJ), new IntPoint(toI, toJ), morphInto == null? null : PieceType.createByName(morphInto));
                var plyStr:String = ply.toNotation(board.currentSituation);
                sidebox.makeMove(plyStr);
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        switch event 
        {
            case ContinuationMove(ply, plyStr, performedBy):
                Networker.emitEvent(Move(ply.from.i, ply.from.j, ply.to.i, ply.to.j, ply.morphInto.getName()));
            default:
        }
    }

    public function handleSideboxEvent(event:SideboxEvent)
    {
        switch event {
            case ChangeOrientationPressed:
                board.revertOrientation();
            case RematchRequested:
                Networker.emitEvent(Rematch);
            case ExportSIPRequested:
                var sip:String = board.shownSituation.serialize();
                Browser.window.prompt(Dictionary.getPhrase(ANALYSIS_EXPORTED_SIP_MESSAGE), sip);
            case ExploreInAnalysisRequest:
                if (!viewingAsParticipatingPlayer)
                    Networker.emitEvent(StopSpectate);
                ScreenManager.toScreen(new Analysis(board.asVariant().serialize(), null));
            case PlyScrollRequest(type):
                board.applyScrolling(type);
            default:
        }
    }

    //TODO: Set actual time for reconnect, spectation, revisit after calling constructor
    public function new(id:Int, whiteLogin:String, blackLogin:String, orientationColour:PieceColor, startSecs:Int, bonusSecs:Int, ?playerColor:PieceColor, ?logForActualization:String)
    {
        super();
        this.id = id;
        this.viewingAsParticipatingPlayer = playerColor != null;

        var parsedData = logForActualization != null? GameLogParser.parse(logForActualization) : null;
        var currentSituation = parsedData != null? parsedData.currentSituation : Situation.starting();

        board = new GameBoard(currentSituation, orientationColour);
        board.state = viewingAsParticipatingPlayer? new NeutralState(board) : new StubState(board);

        if (!viewingAsParticipatingPlayer)
            board.behavior = new EnemyMoveBehavior(board, orientationColour); //Behavior doesn't matter at all, that's just a placeholder
        else if (currentSituation.turnColor == playerColor)
            board.behavior = new PlayerMoveBehavior(board, playerColor);
        else
            board.behavior = new EnemyMoveBehavior(board, playerColor);

        sidebox = new Sidebox(playerColor, startSecs, bonusSecs, whiteLogin, blackLogin, orientationColour, parsedData);
        chatbox = new Chatbox(board.width * 0.45, board.height * 0.75, !viewingAsParticipatingPlayer, parsedData);
        gameinfobox = new GameInfoBox(board.width * 0.45, board.height * 0.23, new TimeControl(startSecs, bonusSecs), whiteLogin, blackLogin, parsedData);

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

        board.addObserver(gameinfobox);
        board.addObserver(sidebox);
        sidebox.addObserver(this);
        sidebox.addObserver(chatbox);
    }
}