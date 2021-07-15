package;

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

    public function appendMessage(author:String, text:String) 
    {
        historyText.htmlText += '<p><b>$author:</b> $text</p>';
        waitAndScroll();
    }

    public function appendLog(text:String) 
    {
        historyText.htmlText += '<p><i>$text</i></p>';
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
            if (messageInput.focus && messageInput.text.trim() != "")
            {
                Networker.sendMessage(messageInput.text);
                appendMessage(Networker.login, messageInput.text);
                messageInput.text = "";
            }
    }

    private function deinit(e) 
    {
        removeEventListener(Event.REMOVED_FROM_STAGE, deinit);
        removeEventListener(KeyboardEvent.KEY_DOWN, deinit);
    }

    private function init(e) 
    {
        removeEventListener(Event.ADDED_TO_STAGE, init);
        addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
        addEventListener(Event.REMOVED_FROM_STAGE, deinit);
    }

    public function new(totalHeight:Float) 
    {
        super();

        history = new ScrollView();
        history.width = WIDTH;
        history.height = totalHeight - 5 - 25;

        historyText = new Label();
        historyText.htmlText = "";
        historyText.width = WIDTH - 20;

        history.addComponent(historyText);
        addChild(history);
        
        messageInput = new TextField();
        //messageInput.placeholder = Dictionary.getPhrase(CHATBOX_MESSAGE_PLACEHOLDER);
        messageInput.width = WIDTH;
        messageInput.height = 25;
        messageInput.y = history.height + 5;
        addChild(messageInput);
        
        addEventListener(Event.ADDED_TO_STAGE, init);
    }
}