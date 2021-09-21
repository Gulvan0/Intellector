package gfx.components.gamefield.modules;

import struct.PieceColor;
import dict.Dictionary;
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

class Chatbox extends Sprite
{
    public static var WIDTH:Float = 260;
    private var history:ScrollView;
    private var historyText:Label;
    private var messageInput:TextField;
    private var isOwnerSpectator:Bool;

    public function appendMessage(author:String, text:String) 
    {
        historyText.htmlText += '<p><b>$author:</b> $text</p>';
        waitAndScroll();
    }

    public function appendSpectatorMessage(author:String, text:String) 
    {
        historyText.htmlText += '<p><i><b>$author:</b> $text</i></p>';
        waitAndScroll();
    }

    public function appendLog(text:String) 
    {
        historyText.htmlText += '<p><i>$text</i></p>';
        waitAndScroll();
    }

    public function onDisconnected(disconnectedColor:PieceColor) 
    {
        appendLog(Dictionary.getColorName(disconnectedColor) + Dictionary.getPhrase(OPPONENT_DISCONNECTED_MESSAGE));
    }

    public function onReconnected(reconnectedColor:PieceColor) 
    {
        appendLog(Dictionary.getColorName(reconnectedColor) + Dictionary.getPhrase(OPPONENT_RECONNECTED_MESSAGE));
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
                    Networker.sendMessage(text);
                    if (isOwnerSpectator)
                        appendSpectatorMessage(Networker.login, text);
                    else 
                        appendMessage(Networker.login, text);
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

    public function terminate() 
    {
        messageInput.disabled = true;
        removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    }

    private function init(e) 
    {
        removeEventListener(Event.ADDED_TO_STAGE, init);
        addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    }

    public function new(totalHeight:Float, isOwnerSpectator:Bool = false) 
    {
        super();
        this.isOwnerSpectator = isOwnerSpectator;

        history = new ScrollView();
        history.width = WIDTH;
        history.height = totalHeight - 5 - 25;

        historyText = new Label();
        historyText.htmlText = "";
        historyText.width = WIDTH - 20;

        history.addComponent(historyText);
        addChild(history);
        
        messageInput = new TextField();
        messageInput.placeholder = Dictionary.getPhrase(CHATBOX_MESSAGE_PLACEHOLDER);
        messageInput.width = WIDTH;
        messageInput.height = 25;
        messageInput.y = history.height + 5;
        addChild(messageInput);
        
        addEventListener(Event.ADDED_TO_STAGE, init);
    }
}