package;

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
        historyText.htmlText += '<b>$author:</b> $text\n';
    }

    public function appendLog(text:String) 
    {
        historyText.htmlText += '<font color="grey"><i>$text</i></font>\n';
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
        messageInput.placeholder = "Message text...";
        messageInput.width = WIDTH;
        messageInput.height = 25;
        messageInput.y = history.height + 5;
        addChild(messageInput);
        
        addEventListener(Event.ADDED_TO_STAGE, init);
    }
}