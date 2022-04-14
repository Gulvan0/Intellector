package gfx.game;

import gfx.game.Sidebox.SideboxEvent;
import gfx.game.GameInfoBox.Outcome;
import gfx.game.Sidebox.ISideboxObserver;
import serialization.GameLogParser;
import net.EventProcessingQueue.INetObserver;
import haxe.ui.containers.VBox;
import net.LoginManager;
import net.ServerEvent;
import struct.PieceColor;
import dict.Dictionary;
import dict.Utils;
import haxe.ui.components.HorizontalScroll;
import haxe.Timer;
import haxe.ui.components.VerticalScroll;
import openfl.events.Event;
import haxe.ui.components.Label;
import openfl.ui.Keyboard;
import openfl.events.KeyboardEvent;
import haxe.ui.components.TextField;
import haxe.ui.containers.ScrollView;
import openfl.display.Sprite;
using StringTools;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/chatbox.xml'))
class Chatbox extends VBox implements INetObserver implements ISideboxObserver
{
    private var isOwnerSpectator:Bool;
    private var actualizationData:GameLogParserOutput;

    public function handleNetEvent(event:ServerEvent)
    {
        switch event
        {
            case Message(author, message):
                appendMessage(author, message, true);
            case SpectatorMessage(author, message):
                if (isOwnerSpectator)
                    appendMessage(author, message, false);
            case GameEnded(winner_color, reason): 
                onGameEnded(GameLogParser.decodeColor(winner_color), GameLogParser.decodeOutcome(reason));
            case PlayerDisconnected(color): 
                appendLog(Utils.getPlayerDisconnectedMessage(PieceColor.createByName(color)));
            case PlayerReconnected(color): 
                appendLog(Utils.getPlayerReconnectedMessage(PieceColor.createByName(color)));
            case NewSpectator(login): 
                appendLog(Dictionary.getPhrase(SPECTATOR_JOINED_MESSAGE, [login]));
            case SpectatorLeft(login): 
                appendLog(Dictionary.getPhrase(SPECTATOR_LEFT_MESSAGE, [login]));
            case DrawOffered:
                appendLog(Dictionary.getPhrase(DRAW_OFFERED_MESSAGE));
            case DrawCancelled:
                appendLog(Dictionary.getPhrase(DRAW_CANCELLED_MESSAGE));
            case DrawAccepted:
                appendLog(Dictionary.getPhrase(DRAW_ACCEPTED_MESSAGE));
            case DrawDeclined:
                appendLog(Dictionary.getPhrase(DRAW_DECLINED_MESSAGE));
            case TakebackOffered:
                appendLog(Dictionary.getPhrase(TAKEBACK_OFFERED_MESSAGE));
            case TakebackCancelled:
                appendLog(Dictionary.getPhrase(TAKEBACK_CANCELLED_MESSAGE));
            case TakebackAccepted:
                appendLog(Dictionary.getPhrase(TAKEBACK_ACCEPTED_MESSAGE));
            case TakebackDeclined:
                appendLog(Dictionary.getPhrase(TAKEBACK_DECLINED_MESSAGE));
            default:
        }
    }

    public function handleSideboxEvent(event:SideboxEvent)
    {
        switch event 
        {
            case OfferDrawPressed:
                appendLog(Dictionary.getPhrase(DRAW_OFFERED_MESSAGE));
            case CancelDrawPressed:
                appendLog(Dictionary.getPhrase(DRAW_CANCELLED_MESSAGE));
            case AcceptDrawPressed:
                appendLog(Dictionary.getPhrase(DRAW_ACCEPTED_MESSAGE));
            case DeclineDrawPressed:
                appendLog(Dictionary.getPhrase(DRAW_DECLINED_MESSAGE));
            case OfferTakebackPressed:
                appendLog(Dictionary.getPhrase(TAKEBACK_OFFERED_MESSAGE));
            case CancelTakebackPressed:
                appendLog(Dictionary.getPhrase(TAKEBACK_CANCELLED_MESSAGE));
            case AcceptTakebackPressed:
                appendLog(Dictionary.getPhrase(TAKEBACK_ACCEPTED_MESSAGE));
            case DeclineTakebackPressed:
                appendLog(Dictionary.getPhrase(TAKEBACK_DECLINED_MESSAGE));
            default:
        }
    }

    private function appendMessage(author:String, text:String, isNotFromSpectator:Bool) 
    {
        if (isNotFromSpectator)
            appendTextGeneric('<p><b>$author:</b> $text</p>');
        else
            appendTextGeneric('<p><i><b>$author:</b> $text</i></p>');
    }

    private function appendLog(text:String) 
    {
        appendTextGeneric('<p><i>$text</i></p>');
    }

    private function appendTextGeneric(htmlString:String)
    {
        if (historyText.htmlText == null || historyText.htmlText == "null")
            historyText.htmlText = htmlString;
        else
            historyText.htmlText += htmlString;
        waitAndScroll();
    }

    private function waitAndScroll() 
    {
        var t:Timer = new Timer(100);
        t.run = () -> {
            t.stop(); 
            scrollToMax();
        }    
    }

    private function scrollToMax() 
    {
        var hscroll = history.findComponent(HorizontalScroll, false);
        if (hscroll != null)
            hscroll.hidden = true;
        var vscroll = history.findComponent(VerticalScroll, false);
        if (vscroll != null)
            vscroll.pos = vscroll.max;
    }

    private function onKeyPress(e:KeyboardEvent) 
    {
        if (e.keyCode == Keyboard.ENTER || e.keyCode == Keyboard.NUMPAD_ENTER)
        {
            if (messageInput.focus)
            {
                var formerText = messageInput.text.trim();
                var text = "";
                var lastIndex = cast(Math.min(500, formerText.length), Int);

                messageInput.text = "";

                for (index in 0...lastIndex)
                    if (isLegalChar(formerText.charCodeAt(index)))
                        text += formerText.charAt(index);

                if (text != "")
                {
                    Networker.emitEvent(Message(text));
                    if (isOwnerSpectator)
                        appendMessage(LoginManager.login, text, false);
                    else 
                        appendMessage(LoginManager.login, text, true);
                }
            }
        }
    }

    private function isLegalChar(code:Int) 
    {
        if (code == "#".code || code == ";".code || code == "/".code || code == "\\".code || code == "|".code)
            return false;
        else if (code < 32)
            return false;
        else if (code > 126 && code < 161)
            return false;
        else 
            return true;
    }

    private function onGameEnded(winnerColor:Null<PieceColor>, outcome:Outcome) 
    {
        messageInput.disabled = true;
        removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
        appendLog(Utils.getGameOverChatMessage(winnerColor, outcome));
    }

    private function applyActualizationData(parsedData:GameLogParserOutput)
    {
        for (entry in parsedData.chatEntries)
        {
            switch entry
            {
                case PlayerMessage(authorColor, text):
                    var author:String = authorColor == White? parsedData.whiteLogin : parsedData.blackLogin;
                    appendMessage(author, text, true);
                case Log(text):
                    appendLog(text);
            }
        }
        if (parsedData.outcome != null)
            onGameEnded(parsedData.winnerColor, parsedData.outcome);
    }

    private function init(e) 
    {
        removeEventListener(Event.ADDED_TO_STAGE, init);
        addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
        if (actualizationData != null)
            applyActualizationData(actualizationData);
    }

    public static function constructFromActualizationData(isOwnerSpectator:Bool, data:ActualizationData):Chatbox
    {
        var chatbox:Chatbox = new Chatbox(isOwnerSpectator);
        chatbox.actualizationData = actualizationData;
        return chatbox;
    }

    public function new(isOwnerSpectator:Bool) 
    {
        super();
        this.isOwnerSpectator = isOwnerSpectator;

        addEventListener(Event.ADDED_TO_STAGE, init);
    }
}