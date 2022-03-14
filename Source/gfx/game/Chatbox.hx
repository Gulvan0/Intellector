package gfx.game;

import haxe.ui.containers.VBox;
import net.LoginManager;
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
class Chatbox extends VBox
{
    private var isOwnerSpectator:Bool;

    //TODO: handleNetEvent(); actualize(); actualizationData as optional constructor parameter; implements INetObserver; make unused from outside methods private

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
        appendLog(Utils.getPlayerDisconnectedMessage(disconnectedColor));
    }

    public function onReconnected(reconnectedColor:PieceColor) 
    {
        appendLog(Utils.getPlayerReconnectedMessage(reconnectedColor));
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
                        appendSpectatorMessage(LoginManager.login, text);
                    else 
                        appendMessage(LoginManager.login, text);
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

    public function deactivate() 
    {
        messageInput.disabled = true;
        removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    }

    private function init(e) 
    {
        removeEventListener(Event.ADDED_TO_STAGE, init);
        addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    }

    public function new(width:Float, height:Float, isOwnerSpectator:Bool = false) 
    {
        super();
        this.isOwnerSpectator = isOwnerSpectator;
        this.width = width;
        this.height = height;
        
        if (isOwnerSpectator)
            messageInput.disabled = true;
        else
            addEventListener(Event.ADDED_TO_STAGE, init);
    }
}