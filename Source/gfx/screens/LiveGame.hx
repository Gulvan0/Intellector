package gfx.screens;

import gfx.game.CompactGame;
import gfx.common.ActionBar.ActionBtn;
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

class LiveGame extends Screen implements INetObserver implements IGameBoardObserver
{
    /**Attains null if a user doesn't participate in the game (is a spectator or browses a past game)**/
    private var playerColor:Null<PieceColor>;
    private var gameID:Int;

    private var board:GameBoard;
    private var sidebox:Sidebox;
    private var chatbox:Chatbox;
    private var gameinfobox:GameInfoBox;

    private var compactGame:CompactGame;

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

    public function handleActionBtnPress(btn:ActionBtn)
    {
        switch btn 
        {
            case Resign:
                Networker.emitEvent(Resign);
            case ChangeOrientation:
                board.revertOrientation();
            case OfferDraw:
                Networker.emitEvent(OfferDraw);
            case CancelDraw:
                Networker.emitEvent(CancelDraw);
            case OfferTakeback:
                Networker.emitEvent(OfferTakeback);
            case CancelTakeback:
                Networker.emitEvent(CancelTakeback);
            case AddTime:
                Networker.emitEvent(AddTime);
            case Rematch:
                Networker.emitEvent(Rematch);
            case ExportSIP:
                var sip:String = board.shownSituation.serialize();
                Browser.window.prompt(Dictionary.getPhrase(ANALYSIS_EXPORTED_SIP_MESSAGE), sip);
            case Analyze:
                if (playerColor == null)
                    Networker.emitEvent(StopSpectate);
                ScreenManager.toScreen(Analysis(board.asVariant().serialize(), null));
            case AcceptDraw:
                Networker.emitEvent(AcceptDraw);
            case DeclineDraw:
                Networker.emitEvent(DeclineDraw);
            case AcceptTakeback:
                Networker.emitEvent(AcceptTakeback);
            case DeclineTakeback:
                Networker.emitEvent(DeclineTakeback);
        }
        chatbox.reactToOwnAction(btn);
    }

    public static function constructFromActualizationData(gameID:Int, actualizationData:ActualizationData, ?orientationColor:PieceColor):LiveGame
    {
        var playingAs:Null<PieceColor> = actualizationData.logParserOutput.getPlayerColor();

        if (orientationColor == null)
            if (playingAs == null)
                orientationColor = White;
            else
                orientationColor = playingAs;

        var sidebox = Sidebox.constructFromActualizationData(actualizationData, orientationColor); //TODO: Set adaptive width/height
        var chatbox = Chatbox.constructFromActualizationData(playingAs == null, actualizationData);
        var gameinfobox = GameInfoBox.constructFromActualizationData(actualizationData);

        return new LiveGame(gameID, playingAs, actualizationData.logParserOutput.currentSituation, sidebox, chatbox, gameinfobox, orientationColor);
    }

    public static function constructFromParams(gameID:Int, whiteLogin:String, blackLogin:String, orientationColor:PieceColor, timeControl:TimeControl, playerColor:Null<PieceColor>):LiveGame 
    {
        var sidebox = new Sidebox(playerColor, timeControl, whiteLogin, blackLogin, orientationColor); //TODO: Set adaptive width/height
        var chatbox = new Chatbox(playerColor == null);
        var gameinfobox = new GameInfoBox(timeControl, whiteLogin, blackLogin);

        return new LiveGame(gameID, playerColor, Situation.starting(), sidebox, chatbox, gameinfobox, orientationColor);
    }

    private function initLarge(sidebox:Sidebox, chatbox:Chatbox, gameinfobox:GameInfoBox)
    {
        this.sidebox = sidebox;
        this.chatbox = chatbox;
        this.gameinfobox = gameinfobox;

        var boardWrapper:SpriteWrapper = new SpriteWrapper();
        boardWrapper.sprite = board;

        var vbox:VBox = new VBox();
        vbox.addComponent(gameinfobox);
        vbox.addComponent(chatbox);

        var hbox:HBox = new HBox();
        hbox.addComponent(vbox);
        hbox.addComponent(boardWrapper);
        hbox.addComponent(sidebox);

        this.addComponent(hbox);

        board.addObserver(gameinfobox);
        board.addObserver(sidebox);
        sidebox.init(handleActionBtnPress, board.applyScrolling);
    }

    private function initCompact(compactGame:CompactGame)
    {
        this.compactGame = compactGame;
    }

    private function new(gameID:Int, playerColor:Null<PieceColor>, currentSituation:Situation, orientationColor:PieceColor)
    {
        super();
        this.gameID = gameID;
        this.playerColor = playerColor;

        board = new GameBoard(currentSituation, orientationColor);
        board.state = playerColor != null? new NeutralState(board) : new StubState(board);

        if (playerColor == null)
            board.behavior = new EnemyMoveBehavior(board, orientationColor); //Behavior doesn't matter at all, that's just a placeholder
        else if (currentSituation.turnColor == playerColor)
            board.behavior = new PlayerMoveBehavior(board, playerColor);
        else
            board.behavior = new EnemyMoveBehavior(board, playerColor);
    }
}