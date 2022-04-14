package gfx.screens;

import struct.ActualizationData;
import gfx.components.Dialogs;
import dict.Dictionary;
import dict.Utils;
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
    /**Attains null if a user doesn't participate in the game (is a spectator or browses a past game)**/
    private var playerColor:Null<PieceColor>;
    private var gameID:Int;

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

    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case Move(fromI, toI, fromJ, toJ, morphInto): //Located in LiveGame since we need board's currentSituation to construct an argument for sidebox
                var ply:Ply = Ply.construct(new IntPoint(fromI, fromJ), new IntPoint(toI, toJ), morphInto == null? null : PieceType.createByName(morphInto));
                var plyStr:String = ply.toNotation(board.currentSituation);
                sidebox.makeMove(plyStr);
            case GameEnded(winner_color, reason):
                Assets.getSound("sounds/notify.mp3").play();
                Dialogs.info(Utils.getGameOverPopUpMessage(GameLogParser.decodeOutcome(winner_color), GameLogParser.decodeColor(winner_color), playerColor), Dictionary.getPhrase(GAME_ENDED));
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
                if (playerColor == null)
                    Networker.emitEvent(StopSpectate);
                ScreenManager.toScreen(Analysis(board.asVariant().serialize(), null));
            case PlyScrollRequest(type):
                board.applyScrolling(type);
            default:
        }
    }

    public static function constructFromActualizationData(gameID:Int, actualizationData:ActualizationData, ?orientationColour:PieceColor):LiveGame
    {
        var playingAs:Null<PieceColor> = actualizationData.logParserOutput.getPlayerColor();

        if (orientationColor == null)
            if (playingAs == null)
                orientationColor = White;
            else
                orientationColor = playingAs;

        var sidebox = Sidebox.constructFromActualizationData(actualizationData, orientationColour); //TODO: Set adaptive width/height
        var chatbox = Chatbox.constructFromActualizationData(playerColor == null, actualizationData);
        var gameinfobox = GameInfoBox.constructFromActualizationData(actualizationData);

        return new LiveGame(gameID, playingAs, actualizationData.logParserOutput.currentSituation, sidebox, chatbox, gameinfobox);
    }

    public static function constructFromParams(gameID:Int, whiteLogin:String, blackLogin:String, orientationColour:PieceColor, timeControl:TimeControl, playerColor:Null<PieceColor>):LiveGame 
    {
        var sidebox = new Sidebox(playerColor, timeControl, whiteLogin, blackLogin, orientationColour); //TODO: Set adaptive width/height
        var chatbox = new Chatbox(playerColor == null);
        var gameinfobox = new GameInfoBox(timeControl, whiteLogin, blackLogin);

        return new LiveGame(gameID, playerColor, Situation.starting(), sidebox, chatbox, gameinfobox);
    }

    private function new(gameID:Int, playerColor:Null<PieceColor>, currentSituation:Situation, sidebox:Sidebox, chatbox:Chatbox, gameinfobox:GameInfoBox)
    {
        super();
        this.gameID = gameID;
        this.playerColor = playerColor;
        this.sidebox = sidebox;
        this.chatbox = chatbox;
        this.gameinfobox = gameinfobox;

        board = new GameBoard(currentSituation, orientationColour);
        board.state = playerColor != null? new NeutralState(board) : new StubState(board);

        if (playerColor == null)
            board.behavior = new EnemyMoveBehavior(board, orientationColour); //Behavior doesn't matter at all, that's just a placeholder
        else if (currentSituation.turnColor == playerColor)
            board.behavior = new PlayerMoveBehavior(board, playerColor);
        else
            board.behavior = new EnemyMoveBehavior(board, playerColor);

        var vbox:VBox = new VBox();
        vbox.addComponent(gameinfobox);
        vbox.addComponent(chatbox);

        var boardWrapper:SpriteWrapper = new SpriteWrapper();
        boardWrapper.sprite = board;

        var hbox:HBox = new HBox();
        hbox.addComponent(vbox);
        hbox.addComponent(boardWrapper);
        hbox.addComponent(vbox);

        this.addComponent(hbox);

        board.addObserver(gameinfobox);
        board.addObserver(sidebox);
        sidebox.addObserver(this);
        sidebox.addObserver(chatbox);
    }
}