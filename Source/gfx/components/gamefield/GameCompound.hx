package gfx.components.gamefield;

import gfx.components.gamefield.modules.Field.MoveType;
import gfx.components.gamefield.analysis.RightPanel;
import struct.IntPoint;
import gfx.components.gamefield.modules.GameInfoBox.Outcome;
import serialization.GameLogDeserializer;
import Networker.GameOverData;
import analysis.AlphaBeta;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import serialization.PlyDeserializer;
import struct.Hex;
import struct.Situation;
import struct.Ply;
import dict.Dictionary;
import Networker.OngoingBattleData;
import struct.PieceType;
import struct.PieceColor;
import haxe.ui.containers.VBox;
import haxe.ui.components.Button;
import Networker.BattleData;
import Networker.MessageData;
import Networker.TimeData;
import Networker.MoveData;
import js.Browser;
import openfl.display.Sprite;
import gfx.components.gamefield.modules.*;
import gfx.components.gamefield.modules.gameboards.*;
using StringTools;
using utils.CallbackTools;

enum GameCompoundType
{
    Active;
    Analysis;
    Spectator;
}

class GameCompound extends Sprite
{
    private var returnBtn:Button;
    private var field:Field;
    private var sidebox:Null<Sidebox>;
    private var chatbox:Null<Chatbox>;
    private var infobox:Null<GameInfoBox>;

    public var type(default, null):GameCompoundType;
    public var playerColor:PieceColor;

    public static function buildActive(data:BattleData, onReturn:Void->Void):GameCompound
    {
        var playerIsWhite:Bool = data.colour == 'white';
        var whiteLogin = playerIsWhite? Networker.login : data.enemy;
        var blackLogin = playerIsWhite? data.enemy : Networker.login;
        
        var field:PlayingField = new PlayingField(playerIsWhite);
        var sidebox:Sidebox = new Sidebox(false, data.startSecs, data.bonusSecs, Networker.login, data.enemy, data.colour == 'white', field.applyScrolling);
        var chatbox:Chatbox = new Chatbox(field.getHeight() * 0.75);
        var infobox:GameInfoBox = new GameInfoBox(Chatbox.WIDTH, field.getHeight() * 0.23, data.startSecs, data.bonusSecs, whiteLogin, blackLogin);

        var compound = new GameCompound(Active, field, sidebox, chatbox, infobox, onReturn);
        compound.playerColor = playerIsWhite? White : Black;
        field.onOwnMoveMade = (ply) -> {
            compound.makeMove(ply, Own);
            Networker.move(ply.from.i, ply.from.j, ply.to.i, ply.to.j, ply.morphInto);
        };
        compound.bindComponentButtonCallbacks();
        return compound;
    }

    public static function buildActiveReconnect(data:OngoingBattleData, onReturn:Void->Void):GameCompound
    {
        var playerIsWhite:Bool = data.whiteLogin.toLowerCase() == Networker.login.toLowerCase();
        var enemyLogin:String = playerIsWhite? data.blackLogin : data.whiteLogin;

        var field:PlayingField = new PlayingField(playerIsWhite);
        var sidebox:Sidebox = new Sidebox(false, data.startSecs, data.bonusSecs, Networker.login, enemyLogin, playerIsWhite, field.applyScrolling);
        var chatbox:Chatbox = new Chatbox(field.getHeight() * 0.75);
        var infobox:GameInfoBox = new GameInfoBox(Chatbox.WIDTH, field.getHeight() * 0.23, data.startSecs, data.bonusSecs, data.whiteLogin, data.blackLogin);

        actualize(data, field, sidebox, infobox, chatbox);

        var compound = new GameCompound(Active, field, sidebox, chatbox, infobox, onReturn);
        compound.playerColor = playerIsWhite? White : Black;
        field.onOwnMoveMade = (ply) -> {
            compound.makeMove(ply, Own);
            Networker.move(ply.from.i, ply.from.j, ply.to.i, ply.to.j, ply.morphInto);
        };
        compound.bindComponentButtonCallbacks();
        return compound;
    }

    public static function buildSpectators(data:OngoingBattleData, onReturn:Void->Void, ?disableChat:Bool = false):GameCompound
    {
        var whiteRequested:Bool = data.requestedColor == "white";
        var watchedColor:PieceColor = whiteRequested? White : Black;
        var bottomLogin:String = whiteRequested? data.whiteLogin : data.blackLogin;
        var upperLogin:String = whiteRequested? data.blackLogin : data.whiteLogin;

        var field:SpectatorsField = new SpectatorsField(watchedColor);
        var sidebox:Sidebox = new Sidebox(true, data.startSecs, data.bonusSecs, bottomLogin, upperLogin, whiteRequested, field.applyScrolling);
        var chatbox:Chatbox = new Chatbox(field.getHeight() * 0.75, true);
        var infobox:GameInfoBox = new GameInfoBox(Chatbox.WIDTH, field.getHeight() * 0.23, data.startSecs, data.bonusSecs, data.whiteLogin, data.blackLogin);
        
        actualize(data, field, sidebox, infobox, chatbox);
        if (disableChat)
            chatbox.terminate();
        
        var compound = new GameCompound(Spectator, field, sidebox, chatbox, infobox, onReturn);
        compound.bindComponentButtonCallbacks();
        return compound;
    }

    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------

    private static function actualize(data:OngoingBattleData, field:Field, sidebox:Sidebox, infobox:GameInfoBox, chatbox:Chatbox)
    {
        for (move in data.currentLog.split(";"))
        {
            var trimmedMove = move.trim();
            if (trimmedMove.charAt(0) == "#")
                processSpecialEntry(trimmedMove.charAt(1), trimmedMove.substr(3), data, infobox, chatbox);
            else if (trimmedMove.length >= 4)
                processNormalEntry(trimmedMove, field, sidebox, infobox);
        }
        if (data.whiteSeconds != null && data.blackSeconds != null)
            sidebox.correctTime(data.whiteSeconds, data.blackSeconds);
    }

    private static function processNormalEntry(trimmedMove:String, field:Field, sidebox:Sidebox, infobox:GameInfoBox)
    {
        var ply = PlyDeserializer.deserialize(trimmedMove);

        sidebox.makeMove(ply, field.currentSituation);
        field.move(ply, Actualization);
        infobox.makeMove(ply);
    }

    private static function processSpecialEntry(typeCode:String, body:String, data:OngoingBattleData, infobox:GameInfoBox, chatbox:Chatbox) 
    {
        var args:Array<String> = body.split("/");
        switch typeCode
        {
            case "P":
                return;
            case "C":
                var author:String = args[0] == "w"? data.whiteLogin : data.blackLogin;
                chatbox.appendMessage(author, args[1]);
            case "R":
                var outcomeCode:String = args[1];
                var winnerColor:Null<PieceColor> = args[0] == "w"? White : args[0] == "b"? Black : null;
                var outcome:Outcome = switch outcomeCode 
                {
                    case "rep": Repetition;
                    case "mat": Mate;
                    case "agr": DrawAgreement;
                    case "100": NoProgress;
                    case "bre": Breakthrough;
                    case "tim": Timeout;
                    case "aba": Abandon;
                    case "abo": Abort;
                    case "res": Resign;
                    default: Abort;
                };
                
                infobox.changeResolution(outcome, winnerColor);
            case "E":
                var eventCode:String = args[0];
                switch eventCode 
                {
                    case "dcn":
                        var disconnectedColor:PieceColor = args[1] == "w"? White : Black;
                        chatbox.onDisconnected(disconnectedColor);
                    case "rcn":
                        var reconnectedColor:PieceColor = args[1] == "w"? White : Black;
                        chatbox.onReconnected(reconnectedColor);
                    case "dof":
                        chatbox.appendLog(Dictionary.getPhrase(DRAW_OFFERED_MESSAGE));
                    case "dca":
                        chatbox.appendLog(Dictionary.getPhrase(DRAW_CANCELLED_MESSAGE));
                    case "dac":
                        chatbox.appendLog(Dictionary.getPhrase(DRAW_ACCEPTED_MESSAGE));
                    case "dde":
                        chatbox.appendLog(Dictionary.getPhrase(DRAW_DECLINED_MESSAGE));
                    case "tof":
                        chatbox.appendLog(Dictionary.getPhrase(TAKEBACK_OFFERED_MESSAGE));
                    case "tca":
                        chatbox.appendLog(Dictionary.getPhrase(TAKEBACK_CANCELLED_MESSAGE));
                    case "tac":
                        chatbox.appendLog(Dictionary.getPhrase(TAKEBACK_ACCEPTED_MESSAGE));
                    case "tde":
                        chatbox.appendLog(Dictionary.getPhrase(TAKEBACK_DECLINED_MESSAGE));
                }
        }        
    }

    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------

    public function makeMove(ply:Ply, type:MoveType) 
    {
        var situation:Situation = field.currentSituation.copy();

        sidebox.makeMove(ply, situation);
        if (infobox != null)
            infobox.makeMove(ply);
        if (type != Own)
            field.move(ply, type);
    }

    public function onMove(data:MoveData)
    {
        makeMove(Ply.fromMoveData(data), ByOpponent);
    }

    public function onTimeCorrection(data:TimeData)
    {
        sidebox.correctTime(data.whiteSeconds, data.blackSeconds);
    }

    public function onMessage(data:MessageData)
    {
        chatbox.appendMessage(data.issuer_login, data.message);
    }

    public function onSpectatorMessage(data:MessageData)
    {
        chatbox.appendSpectatorMessage(data.issuer_login, data.message);
    }

    public function onSpectatorConnected(data:{login:String})
    {
        chatbox.appendLog('${data.login}' + Dictionary.getPhrase(SPECTATOR_JOINED_MESSAGE));
    }

    public function onSpectatorDisonnected(data:{login:String})
    {
        chatbox.appendLog('${data.login}' + Dictionary.getPhrase(SPECTATOR_LEFT_MESSAGE));
    }

    public function onOpponentReconnected(data)
    {
        var color = Reflect.hasField(data, "color")? PieceColor.createByName(data.color) : opposite(playerColor);
        chatbox.onReconnected(color);
    }

    public function onOpponentDisconnected(data)
    {
        var color = Reflect.hasField(data, "color")? PieceColor.createByName(data.color) : opposite(playerColor);
        chatbox.onDisconnected(color);
    }

    public function onDrawOffered()
    {
        if (type == Active)
            sidebox.showDrawRequestBox();
        if (chatbox != null)
            chatbox.appendLog(Dictionary.getPhrase(DRAW_OFFERED_MESSAGE));
    }

    public function onDrawCancelled()
    {
        if (type == Active)
            sidebox.hideDrawRequestBox();
        if (chatbox != null)
            chatbox.appendLog(Dictionary.getPhrase(DRAW_CANCELLED_MESSAGE));
    }

    public function onDrawAccepted()
    {
        if (chatbox != null)
            chatbox.appendLog(Dictionary.getPhrase(DRAW_ACCEPTED_MESSAGE));
    }

    public function onDrawDeclined()
    {
        if (type == Active)
            sidebox.drawOfferShowCancelHide();
        if (chatbox != null)
            chatbox.appendLog(Dictionary.getPhrase(DRAW_DECLINED_MESSAGE));
    }

    public function onTakebackOffered()
    {
        if (type == Active)
            sidebox.showTakebackRequestBox();
        if (chatbox != null)
            chatbox.appendLog(Dictionary.getPhrase(TAKEBACK_OFFERED_MESSAGE));
    }

    public function onTakebackCancelled()
    {
        if (type == Active)
            sidebox.hideTakebackRequestBox();
        if (chatbox != null)
            chatbox.appendLog(Dictionary.getPhrase(TAKEBACK_CANCELLED_MESSAGE));
    }

    public function onTakebackAccepted()
    {
        if (type == Active)
            sidebox.takebackOfferShowCancelHide();
        if (chatbox != null)
            chatbox.appendLog(Dictionary.getPhrase(TAKEBACK_ACCEPTED_MESSAGE));
    }

    public function onTakebackDeclined()
    {
        if (type == Active)
            sidebox.takebackOfferShowCancelHide();
        if (chatbox != null)
            chatbox.appendLog(Dictionary.getPhrase(TAKEBACK_DECLINED_MESSAGE));
    }

    public function onRollbackCommand(cnt:Int) 
    {
        field.revertPlys(cnt);
        sidebox.revertPlys(cnt);
        if (infobox != null)
            infobox.revertPlys(cnt);
    }

    private function bindComponentButtonCallbacks() 
    {
        sidebox.onOfferDrawPressed = onOfferDrawPressed;
        sidebox.onCancelDrawPressed = onCancelDrawPressed;
        sidebox.onAcceptDrawPressed = onAcceptDrawPressed;
        sidebox.onDeclineDrawPressed = onDeclineDrawPressed;
        sidebox.onOfferTakebackPressed = onOfferTakebackPressed;
        sidebox.onCancelTakebackPressed = onCancelTakebackPressed;
        sidebox.onAcceptTakebackPressed = onAcceptTakebackPressed;
        sidebox.onDeclineTakebackPressed = onDeclineTakebackPressed;
    }

    private function onOfferDrawPressed()
    {
        sidebox.drawOfferHideCancelShow();
        chatbox.appendLog(Dictionary.getPhrase(DRAW_OFFERED_MESSAGE));
        Networker.offerDraw();
    }

    private function onCancelDrawPressed()
    {
        sidebox.drawOfferShowCancelHide();
        chatbox.appendLog(Dictionary.getPhrase(DRAW_CANCELLED_MESSAGE));
        Networker.cancelDraw();
    }

    private function onAcceptDrawPressed()
    {
        sidebox.hideDrawRequestBox();
        chatbox.appendLog(Dictionary.getPhrase(DRAW_ACCEPTED_MESSAGE));
        Networker.acceptDraw();
    }

    private function onDeclineDrawPressed()
    {
        sidebox.hideDrawRequestBox();
        chatbox.appendLog(Dictionary.getPhrase(DRAW_DECLINED_MESSAGE));
        Networker.declineDraw();
    }

    private function onOfferTakebackPressed()
    {
        if (sidebox.hasIncomingTakebackRequest())
            chatbox.appendLog(Dictionary.getPhrase(TAKEBACK_ACCEPTED_MESSAGE));
        else
        {
            sidebox.takebackOfferHideCancelShow();
            chatbox.appendLog(Dictionary.getPhrase(TAKEBACK_OFFERED_MESSAGE));
        }
        
        Networker.offerTakeback();
    }

    private function onCancelTakebackPressed()
    {
        sidebox.takebackOfferShowCancelHide();
        chatbox.appendLog(Dictionary.getPhrase(TAKEBACK_CANCELLED_MESSAGE));
        Networker.cancelTakeback();
    }

    private function onAcceptTakebackPressed()
    {
        sidebox.hideTakebackRequestBox();
        chatbox.appendLog(Dictionary.getPhrase(TAKEBACK_ACCEPTED_MESSAGE));
        Networker.acceptTakeback();
    }

    private function onDeclineTakebackPressed()
    {
        sidebox.hideTakebackRequestBox();
        chatbox.appendLog(Dictionary.getPhrase(TAKEBACK_DECLINED_MESSAGE));
        Networker.declineTakeback();
    }

    public function terminate(data:GameOverData)
    {
        var winnerColor:PieceColor = GameLogDeserializer.decodeColor(data.winner_color);
        var outcome:Outcome = switch data.reason
        {
            case 'mate': Mate;
			case 'breakthrough': Breakthrough;
			case 'timeout': Timeout;
			case 'resignation': Resign;
			case 'abandon': Abandon;
			case 'threefoldrepetition': Repetition;
			case 'hundredmoverule': NoProgress;
            case 'drawagreement': DrawAgreement;
            case 'abort': Abort;
            default: Mate;
        }

        field.terminated = true;
        if (sidebox != null)
            sidebox.terminate();
        if (infobox != null)
            infobox.changeResolution(outcome, winnerColor);
        if (chatbox != null)
        {
            chatbox.appendLog(Dictionary.getGameOverChatMessage(winnerColor, data.reason));
            chatbox.terminate();
        }
        returnBtn.visible = true;
    }

    private function new(type, field, sidebox, chatbox, infobox, ?onReturn:Void->Void) 
    {
        super();

        this.type = type;
        this.field = field;
        this.sidebox = sidebox;
        this.chatbox = chatbox;
        this.infobox = infobox;

        field.x = (Browser.window.innerWidth - field.width) / 2;
		field.y = 100;
		addChild(field);

        if (sidebox != null)
        {
            sidebox.x = field.right - 22;
            sidebox.y = field.top;
            addChild(sidebox);
        }

		if (chatbox != null)
        {
            chatbox.x = field.x - Chatbox.WIDTH - Field.a - 30;
            chatbox.y = field.y + field.getHeight() * 0.25 - Field.a * Math.sqrt(3) / 2;
            addChild(chatbox);
        }

		if (infobox != null)
        {
            infobox.x = field.x - Chatbox.WIDTH - Field.a - 30;
            infobox.y = field.y - Field.a * Math.sqrt(3) / 2;
            addChild(infobox);
        }

        if (onReturn != null)
        {
            returnBtn = new Button();
		    returnBtn.width = 100;
		    returnBtn.text = Dictionary.getPhrase(RETURN);
            returnBtn.onClick = (e) -> {onReturn();};
            if (type == Active)
                returnBtn.visible = false;
            
            returnBtn.x = 10;
		    returnBtn.y = 10;
		    addChild(returnBtn);
        }
    }    
}