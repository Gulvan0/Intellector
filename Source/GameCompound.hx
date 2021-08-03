package;

import GameInfoBox.Outcome;
import Networker.GameOverData;
import analysis.AlphaBeta;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import serialization.PlyDeserializer;
import struct.Hex;
import struct.Situation;
import struct.Ply;
import gameboards.AnalysisField;
import gameboards.SpectatorsField;
import gameboards.PlayingField;
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
        var whiteLogin = data.colour == 'white'? Networker.login : data.enemy;
        var blackLogin = data.colour == 'black'? Networker.login : data.enemy;
        
        var field:PlayingField = new PlayingField(data.colour);
        var sidebox:Sidebox = new Sidebox(false, data.startSecs, data.bonusSecs, Networker.login, data.enemy, data.colour == 'white');
        var chatbox:Chatbox = new Chatbox(field.getHeight() * 0.75);
        var infobox:GameInfoBox = new GameInfoBox(Chatbox.WIDTH, field.getHeight() * 0.23, data.startSecs, data.bonusSecs, whiteLogin, blackLogin, data.colour == 'white');

        var compound = new GameCompound(Active, field, sidebox, chatbox, infobox, onReturn);
        compound.playerColor = data.colour == 'white'? White : Black;
        field.onPlayerMadeMove = compound.onMove;
        compound.bindComponentButtonCallbacks();
        return compound;
    }

    public static function buildActiveReconnect(data:OngoingBattleData, onReturn:Void->Void):GameCompound
    {
        var playerIsWhite:Bool = data.whiteLogin.toLowerCase() == Networker.login.toLowerCase();
        var enemyLogin:String = playerIsWhite? data.blackLogin : data.whiteLogin;

        var field:PlayingField = new PlayingField(playerIsWhite? 'white' : 'black', data);
        var sidebox:Sidebox = new Sidebox(false, data.startSecs, data.bonusSecs, Networker.login, enemyLogin, playerIsWhite);
        var chatbox:Chatbox = new Chatbox(field.getHeight() * 0.75);
        var infobox:GameInfoBox = new GameInfoBox(Chatbox.WIDTH, field.getHeight() * 0.23, data.startSecs, data.bonusSecs, data.whiteLogin, data.blackLogin, playerIsWhite);

        actualizeBoxes(data, field, sidebox, infobox);

        var compound = new GameCompound(Active, field, sidebox, chatbox, infobox, onReturn);
        compound.playerColor = playerIsWhite? White : Black;
        field.onPlayerMadeMove = compound.onMove;
        compound.bindComponentButtonCallbacks();
        return compound;
    }

    public static function buildSpectators(data:OngoingBattleData, onReturn:Void->Void):GameCompound
    {
        var whiteRequested:Bool = data.requestedColor == "white";
        var watchedColor:PieceColor = whiteRequested? White : Black;
        var bottomLogin:String = whiteRequested? data.whiteLogin : data.blackLogin;
        var upperLogin:String = whiteRequested? data.blackLogin : data.whiteLogin;

        var field:SpectatorsField = new SpectatorsField(data.position, watchedColor);
        var sidebox:Sidebox = new Sidebox(true, data.startSecs, data.bonusSecs, bottomLogin, upperLogin, whiteRequested);
        //var chatbox:Chatbox;
        //var infobox:GameInfoBox;
        
        actualizeBoxes(data, field, sidebox);
        
        var compound = new GameCompound(Spectator, field, sidebox, null, null, onReturn);
        compound.bindComponentButtonCallbacks();
        return compound;
    }

    public static function buildAnalysis(onReturn:Void->Void):GameCompound
    {
        var field:AnalysisField = new AnalysisField();

        return new GameCompound(Analysis, field, null, null, null, onReturn);
    }

    private static function actualizeBoxes(data:OngoingBattleData, field:Field, sidebox:Sidebox, ?infobox:GameInfoBox)
    {
        var situation:Situation = Situation.starting();
        for (move in data.currentLog.split(";"))
        {
            var trimmedMove = StringTools.trim(move);
            if (StringTools.contains(trimmedMove, ":") || trimmedMove.length < 4)
                continue;

            var ply = PlyDeserializer.deserialize(trimmedMove);

            field.plyHistory.push(ply.toReversible(situation));
            field.plyPointer++;

            sidebox.makeMove(ply, situation);

            if (infobox != null)
                infobox.makeMove(ply);

            situation = situation.makeMove(ply);
        }
        field.currentSituation = situation.copy();
        sidebox.correctTime(data.whiteSeconds, data.blackSeconds);
    }

    public function onMove(data:MoveData)
    {
        var ply:Ply = new Ply();
        ply.from = new IntPoint(data.fromI, data.fromJ);
        ply.to = new IntPoint(data.toI, data.toJ);
        ply.morphInto = data.morphInto == null? null : PieceType.createByName(data.morphInto);

        var situation:Situation = field.currentSituation.copy();

        sidebox.makeMove(ply, situation);
        if (infobox != null)
            infobox.makeMove(ply);
        if (data.issuer_login != Networker.login)
            field.move(ply);
        else
            Networker.move(data.fromI, data.fromJ, data.toI, data.toJ, data.morphInto == null? null : PieceType.createByName(data.morphInto));
    }

    public function onTimeCorrection(data:TimeData)
    {
        sidebox.correctTime(data.whiteSeconds, data.blackSeconds);
    }

    public function onMessage(data:MessageData)
    {
        chatbox.appendMessage(data.issuer_login, data.message);
    }

    public function onSpectatorConnected(data:{login:String})
    {
        chatbox.appendLog('${data.login}' + Dictionary.getPhrase(SPECTATOR_JOINED_MESSAGE));
    }

    public function onSpectatorDisonnected(data:{login:String})
    {
        chatbox.appendLog('${data.login}' + Dictionary.getPhrase(SPECTATOR_LEFT_MESSAGE));
    }

    public function onOpponentReconnected()
    {
        chatbox.appendLog(Dictionary.getColorName(opposite(playerColor)) + Dictionary.getPhrase(OPPONENT_RECONNECTED_MESSAGE));
    }

    public function onOpponentDisconnected()
    {
        chatbox.appendLog(Dictionary.getColorName(opposite(playerColor)) + Dictionary.getPhrase(OPPONENT_DISCONNECTED_MESSAGE));
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
        sidebox.onHomePressed = field.homePly;
        sidebox.onPrevPressed = field.prevPly;
        sidebox.onNextPressed = field.nextPly;
        sidebox.onEndPressed = field.endPly;
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
        var winnerColor:PieceColor = data.winner_color == 'white'? White : Black;
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
            default: Mate;
        }

        field.terminated = true;
        if (sidebox != null)
            sidebox.terminate();
        if (infobox != null)
            infobox.changeResolution(outcome, winnerColor);
        if (chatbox != null)
            chatbox.appendLog(Dictionary.getGameOverChatMessage(winnerColor, data.reason));
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

        if (type == Analysis)
        {
            var panel:AnalysisBoardPanel = new AnalysisBoardPanel(cast(field, AnalysisField));
            panel.x = field.x + field.width + 10;
            panel.y = field.y + (field.getHeight() - 40 - Math.sqrt(3) * Field.a) / 2;
            addChild(panel);

            cast(field, AnalysisField).onMadeMove = panel.deprecateScore;
        }
    }    
}