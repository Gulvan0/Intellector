package gfx.game;

import utils.StringUtils;
import dict.Phrase;
import gfx.game.GameActionBar.ActionBtn;
import struct.Outcome;
import serialization.GameLogParser;
import net.EventProcessingQueue.INetObserver;
import haxe.ui.containers.VBox;
import net.shared.ServerEvent;
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

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/live/chatbox.xml'))
class Chatbox extends VBox implements INetObserver
{
    private var isOwnerSpectator:Bool;

    public function handleNetEvent(event:ServerEvent)
    {
        switch event
        {
            case Message(author, message):
                appendMessage(author, message, true);
            case SpectatorMessage(author, message):
                if (isOwnerSpectator)
                    appendMessage(author, message, false);
            case GameEnded(winner_color, reason, _, _): 
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

    public function reactToOwnAction(btn:ActionBtn)
    {
        var message:Null<Phrase> = switch btn 
        {
            case OfferDraw: DRAW_OFFERED_MESSAGE;
            case CancelDraw: DRAW_CANCELLED_MESSAGE;
            case OfferTakeback: TAKEBACK_OFFERED_MESSAGE;
            case CancelTakeback: TAKEBACK_CANCELLED_MESSAGE;
            case AcceptDraw: DRAW_ACCEPTED_MESSAGE;
            case DeclineDraw: DRAW_DECLINED_MESSAGE;
            case AcceptTakeback: TAKEBACK_ACCEPTED_MESSAGE;
            case DeclineTakeback: TAKEBACK_DECLINED_MESSAGE;
            default: null;
        };
        if (message != null)
            appendLog(Dictionary.getPhrase(message));
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
            if (messageInput.focus)
                send();
    }

    private function send() 
    {
        var text = StringUtils.clean(messageInput.text, 500);

        messageInput.text = "";

        if (text != "")
        {
            Networker.emitEvent(Message(text));
            if (isOwnerSpectator)
                appendMessage(LoginManager.getLogin(), text, false);
            else 
                appendMessage(LoginManager.getLogin(), text, true);
        }
    }

    private function onGameEnded(winnerColor:Null<PieceColor>, outcome:Outcome) 
    {
        messageInput.disabled = true;
        removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
        appendLog(Dictionary.getPhrase(GAME_CHATBOX_GAME_OVER_MESSAGE(outcome, winnerColor)));
    }

    private function actualize(parserOutput:GameLogParserOutput, e)
    {
        for (entry in parserOutput.chatEntries)
        {
            switch entry
            {
                case PlayerMessage(authorColor, text):
                    var author:String = authorColor == White? parserOutput.whiteLogin : parserOutput.blackLogin;
                    appendMessage(author, text, true);
                case Log(text):
                    appendLog(text);
            }
        }
        if (parserOutput.outcome != null)
            onGameEnded(parserOutput.winnerColor, parserOutput.outcome);
    }

    public function init(constructor:LiveGameConstructor)
    {
        switch constructor 
        {
            case New(_, _, _, _, _):
                this.isOwnerSpectator = false;
            case Ongoing(parsedData, _, _, _, followedPlayerLogin):
                this.isOwnerSpectator = followedPlayerLogin != null;
                addEventListener(Event.ADDED_TO_STAGE, actualize.bind(parsedData));
            case Past(parsedData, _):
                this.isOwnerSpectator = true;
                addEventListener(Event.ADDED_TO_STAGE, actualize.bind(parsedData));
        }

        addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    }

    public function new() 
    {
        super();
    }
}