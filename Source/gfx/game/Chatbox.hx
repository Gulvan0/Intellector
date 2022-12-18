package gfx.game;

import haxe.ui.events.MouseEvent;
import net.Requests;
import haxe.ui.styles.Style;
import utils.StringUtils;
import dict.Phrase;
import gfx.game.GameActionBar.ActionBtn;
import net.shared.Outcome;
import serialization.GameLogParser;
import net.EventProcessingQueue.INetObserver;
import haxe.ui.containers.VBox;
import net.shared.ServerEvent;
import net.shared.PieceColor;
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
    private var ownerColor:Null<PieceColor>;

    public function handleNetEvent(event:ServerEvent)
    {
        switch event
        {
            case Message(authorRef, message):
                appendMessage(authorRef, message, true);
            case SpectatorMessage(authorRef, message):
                if (ownerColor == null)
                    appendMessage(authorRef, message, false);
            case GameEnded(outcome, _, _, _): 
                onGameEnded(outcome);
            case PlayerDisconnected(color): 
                appendLog(Dictionary.getPhrase(PLAYER_DISCONNECTED_MESSAGE(color)));
            case PlayerReconnected(color): 
                appendLog(Dictionary.getPhrase(PLAYER_RECONNECTED_MESSAGE(color)));
            case NewSpectator(ref): 
                appendLog(Dictionary.getPhrase(SPECTATOR_JOINED_MESSAGE(Utils.playerRef(ref))));
            case SpectatorLeft(ref): 
                appendLog(Dictionary.getPhrase(SPECTATOR_LEFT_MESSAGE(Utils.playerRef(ref))));
            case DrawOffered(color):
                appendLog(Dictionary.getPhrase(DRAW_OFFERED_MESSAGE(color)));
            case DrawCancelled(color):
                appendLog(Dictionary.getPhrase(DRAW_CANCELLED_MESSAGE(color)));
            case DrawAccepted(color):
                appendLog(Dictionary.getPhrase(DRAW_ACCEPTED_MESSAGE(color)));
            case DrawDeclined(color):
                appendLog(Dictionary.getPhrase(DRAW_DECLINED_MESSAGE(color)));
            case TakebackOffered(color):
                appendLog(Dictionary.getPhrase(TAKEBACK_OFFERED_MESSAGE(color)));
            case TakebackCancelled(color):
                appendLog(Dictionary.getPhrase(TAKEBACK_CANCELLED_MESSAGE(color)));
            case TakebackAccepted(color):
                appendLog(Dictionary.getPhrase(TAKEBACK_ACCEPTED_MESSAGE(color)));
            case TakebackDeclined(color):
                appendLog(Dictionary.getPhrase(TAKEBACK_DECLINED_MESSAGE(color)));
            case TimeAdded(color, _):
                appendLog(Dictionary.getPhrase(TIME_ADDED_MESSAGE(color)));
            default:
        }
    }

    public function reactToOwnAction(btn:ActionBtn)
    {
        var message:Null<Phrase> = switch btn 
        {
            case OfferDraw: DRAW_OFFERED_MESSAGE(ownerColor);
            case CancelDraw: DRAW_CANCELLED_MESSAGE(ownerColor);
            case OfferTakeback: TAKEBACK_OFFERED_MESSAGE(ownerColor);
            case CancelTakeback: TAKEBACK_CANCELLED_MESSAGE(ownerColor);
            case AcceptDraw: DRAW_ACCEPTED_MESSAGE(ownerColor);
            case DeclineDraw: DRAW_DECLINED_MESSAGE(ownerColor);
            case AcceptTakeback: TAKEBACK_ACCEPTED_MESSAGE(ownerColor);
            case DeclineTakeback: TAKEBACK_DECLINED_MESSAGE(ownerColor);
            default: null;
        };
        if (message != null)
            appendLog(Dictionary.getPhrase(message));
    }

    private function appendMessage(authorRef:String, text:String, isNotFromSpectator:Bool) 
    {
        var guestAuthorStyle:Style = {fontBold: true, fontItalic: !isNotFromSpectator};
        var normalAuthorStyle:Style = {fontBold: true, fontItalic: !isNotFromSpectator, pointerEvents: 'true', backgroundColor: 0, backgroundOpacity: 0, cursor: 'pointer'};
        var hoverAuthorStyle:Style = normalAuthorStyle.clone();
        hoverAuthorStyle.color = 0x428fd8;

        var authorLabel:Label = new Label();
        authorLabel.percentWidth = 100;
        authorLabel.text = Utils.playerRef(authorRef);

        if (authorRef.charAt(0) != "_")
        {
            authorLabel.customStyle = normalAuthorStyle;
            authorLabel.onMouseOver = e -> {
                authorLabel.customStyle = hoverAuthorStyle;
            };
            authorLabel.onMouseOut = e -> {
                authorLabel.customStyle = normalAuthorStyle;
            };
            authorLabel.onClick = e -> {
                Requests.getMiniProfile(authorRef);
            };
        }
        else
            authorLabel.customStyle = guestAuthorStyle;

        var textLabel:Label = new Label();
        textLabel.percentWidth = 100;
        textLabel.text = text;
        textLabel.customStyle = {fontItalic: !isNotFromSpectator};

        history.addComponent(authorLabel);
        history.addComponent(textLabel);
        Timer.delay(scrollToMax, 50);
    }

    private function appendLog(text:String) 
    {
        var label:Label = new Label();
        label.percentWidth = 100;
        label.text = text;
        label.customStyle = {fontItalic: true, textAlign: 'center'};

        history.addComponent(label);
        Timer.delay(scrollToMax, 50);
    }

    private function scrollToMax() 
    {
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

    @:bind(sendBtn, MouseEvent.CLICK)
    private function onSendBtnPressed(e)
    {
        send();
    }

    private function send() 
    {
        var ownRef:String = LoginManager.getRef();
        var text = StringUtils.clean(messageInput.text, 500);

        messageInput.text = "";

        if (text != "")
        {
            Networker.emitEvent(Message(text));
            if (ownerColor == null)
                appendMessage(ownRef, text, false);
            else 
                appendMessage(ownRef, text, true);
        }
    }

    private function onGameEnded(outcome:Outcome) 
    {
        messageInput.disabled = true;
        sendBtn.disabled = true;
        removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
        appendLog(dict.Utils.chatboxGameOverMessage(outcome));
    }

    private function actualize(parserOutput:GameLogParserOutput, e)
    {
        for (entry in parserOutput.chatEntries)
        {
            switch entry
            {
                case PlayerMessage(authorColor, text):
                    var authorRef:String = authorColor == White? parserOutput.whiteRef : parserOutput.blackRef;
                    appendMessage(authorRef, text, true);
                case Log(text):
                    appendLog(text);
            }
        }
        if (parserOutput.outcome != null)
            onGameEnded(parserOutput.outcome);
    }

    public function init(constructor:LiveGameConstructor)
    {
        switch constructor 
        {
            case New(whiteRef, blackRef, _, _, _, _):
                if (LoginManager.isPlayer(whiteRef))
                    this.ownerColor = White;
                else if (LoginManager.isPlayer(blackRef))
                    this.ownerColor = Black;
                else
                    this.ownerColor = null;
            case Ongoing(parsedData, _, _):
                this.ownerColor = parsedData.getPlayerColor();
                addEventListener(Event.ADDED_TO_STAGE, actualize.bind(parsedData));
            case Past(parsedData, _):
                this.ownerColor = null;
                addEventListener(Event.ADDED_TO_STAGE, actualize.bind(parsedData));
        }

        addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    }

    public function new() 
    {
        super();
    }
}