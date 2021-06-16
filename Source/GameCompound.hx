package;

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

class GameCompound extends Sprite
{
    private var returnBtn:Button;
    private var field:Field;
    private var sidebox:Null<Sidebox>;
    private var chatbox:Null<Chatbox>;
    private var infobox:Null<GameInfoBox>;

    public var playerColor:PieceColor;

    public static function buildActive(data:BattleData):GameCompound
    {
        var whiteLogin = data.colour == 'white'? Networker.login : data.enemy;
        var blackLogin = data.colour == 'black'? Networker.login : data.enemy;
        
        var field:PlayingField = new PlayingField(data.colour);
        var sidebox:Sidebox = new Sidebox(data.startSecs, data.bonusSecs, Networker.login, data.enemy, data.colour == 'white');
        var chatbox:Chatbox = new Chatbox(field.getHeight() * 0.75);
        var infobox:GameInfoBox = new GameInfoBox(Chatbox.WIDTH, field.getHeight() * 0.23, data.startSecs, data.bonusSecs, whiteLogin, blackLogin, data.colour == 'white');

        var compound = new GameCompound(field, sidebox, chatbox, infobox);
        compound.playerColor = data.colour == 'white'? White : Black;
        field.onPlayerMadeMove = compound.onMove;
        return compound;
    }

    public static function buildActiveReconnect(data:OngoingBattleData):GameCompound
    {
        var playerIsWhite:Bool = data.whiteLogin == Networker.login;
        var enemyLogin:String = playerIsWhite? data.blackLogin : data.whiteLogin;

        var field:PlayingField = new PlayingField(playerIsWhite? 'white' : 'black', data);
        var sidebox:Sidebox = new Sidebox(data.startSecs, data.bonusSecs, Networker.login, enemyLogin, playerIsWhite);
        var chatbox:Chatbox = new Chatbox(field.getHeight() * 0.75);
        var infobox:GameInfoBox = new GameInfoBox(Chatbox.WIDTH, field.getHeight() * 0.23, data.startSecs, data.bonusSecs, data.whiteLogin, data.blackLogin, playerIsWhite);

        for (move in data.currentLog.split(";"))
        {
            var trimmed = StringTools.trim(move);
            if (StringTools.contains(trimmed, ":") || trimmed.length < 4)
                continue;

            infobox.makeMove(Std.parseInt(trimmed.charAt(0)), Std.parseInt(trimmed.charAt(1)), Std.parseInt(trimmed.charAt(2)), Std.parseInt(trimmed.charAt(3)), trimmed.length == 4? null : PieceType.createByName(trimmed.substr(4)));
        }

        var color:PieceColor = White;
        for (move in data.movesPlayed)
        {
            sidebox.writeMove(color, move);
            color = color == White? Black : White;
        }
        sidebox.correctTime(data.whiteSeconds, data.blackSeconds);
        sidebox.launchTimer();

        var compound = new GameCompound(field, sidebox, chatbox, infobox);
        compound.playerColor = playerIsWhite? White : Black;
        field.onPlayerMadeMove = compound.onMove;
        return compound;
    }

    public static function buildSpectators(data:OngoingBattleData, onReturn:Void->Void):GameCompound
    {
        var whiteRequested:Bool = data.requestedColor == "white";
        var watchedColor:PieceColor = whiteRequested? White : Black;
        var bottomLogin:String = whiteRequested? data.whiteLogin : data.blackLogin;
        var upperLogin:String = whiteRequested? data.blackLogin : data.whiteLogin;

        var field:SpectatorsField = new SpectatorsField(data.position, watchedColor);
        var sidebox:Sidebox = new Sidebox(data.startSecs, data.bonusSecs, bottomLogin, upperLogin, whiteRequested);
        var color:PieceColor = White;
        for (move in data.movesPlayed)
        {
            sidebox.writeMove(color, move);
            color = color == White? Black : White;
        }
        sidebox.correctTime(data.whiteSeconds, data.blackSeconds);
        sidebox.launchTimer();

        //var chatbox:Chatbox;
        //var infobox:GameInfoBox;
        
        return new GameCompound(field, sidebox, null, null, onReturn);
    }

    public static function buildAnalysis(onReturn:Void->Void):GameCompound
    {
        var field:AnalysisField = new AnalysisField();

        return new GameCompound(field, null, null, null, onReturn);
    }

    public function onMove(data:MoveData)
    {
        var from = new IntPoint(data.fromI, data.fromJ);
        var to = new IntPoint(data.toI, data.toJ);
        var movingFigure = field.getFigure(from);
        var ontoFigure = field.getFigure(to);
        var morphedInto = data.morphInto == null? null : PieceType.createByName(data.morphInto);
        var capture = ontoFigure != null && ontoFigure.color != movingFigure.color;
        var mate = capture && ontoFigure.type == Intellector;
        var castle = ontoFigure != null && ontoFigure.color == movingFigure.color && (ontoFigure.type == Intellector && movingFigure.type == Defensor || ontoFigure.type == Defensor && movingFigure.type == Intellector);

        sidebox.makeMove(movingFigure.color, movingFigure.type, to, capture, mate, castle, morphedInto);
        if (infobox != null)
            infobox.makeMove(data.fromI, data.fromJ, data.toI, data.toJ, morphedInto);
        if (data.issuer_login != Networker.login)
            field.move(from, to, morphedInto);
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

    public function terminate()
    {
        if (sidebox != null)
            sidebox.terminate();
    }

    private function new(field, sidebox, chatbox, infobox, ?onReturn:Void->Void) 
    {
        super();

        this.field = field;
        this.sidebox = sidebox;
        this.chatbox = chatbox;
        this.infobox = infobox;

        field.x = (Browser.window.innerWidth - field.width) / 2;
		field.y = 100;
		addChild(field);

        if (sidebox != null)
        {
            sidebox.x = field.x + field.width + 10;
            sidebox.y = field.y + (field.getHeight() - 380 - Math.sqrt(3) * Field.a) / 2;
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
            
            returnBtn.x = 10;
		    returnBtn.y = 10;
		    addChild(returnBtn);
        }

        if (Std.isOfType(field, AnalysisField))
        {
            var actionButtons:VBox = new VBox();

            var clearBtn = new Button();
            clearBtn.width = 200;
            clearBtn.text = Dictionary.getPhrase(ANALYSIS_CLEAR);
    
            clearBtn.onClick = (e) -> {
                cast(field, AnalysisField).clearBoard();
            }
    
            actionButtons.addComponent(clearBtn);
    
            var resetBtn = new Button();
            resetBtn.width = 200;
            resetBtn.text = Dictionary.getPhrase(ANALYSIS_RESET);
    
            resetBtn.onClick = (e) -> {
                cast(field, AnalysisField).reset();
            }
    
            actionButtons.addComponent(resetBtn);
    
            actionButtons.x = field.x + field.width + 10;
            actionButtons.y = field.y + (field.getHeight() - 40 - Math.sqrt(3) * Field.a) / 2;
            addChild(actionButtons);
        }
    }    
}