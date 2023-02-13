package gfx.game;

import haxe.ui.components.VerticalScroll;
import haxe.ui.components.Label;
import haxe.Timer;
import haxe.ui.containers.VBox;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/live/bot_chat.xml"))
class BotChat extends VBox
{
    public function appendBotMessage(botName:String, text:String) 
    {
        var authorLabel:Label = new Label();
        authorLabel.percentWidth = 100;
        authorLabel.text = botName;
        authorLabel.customStyle = {fontBold: true};

        var textLabel:Label = new Label();
        textLabel.percentWidth = 100;
        textLabel.text = text;

        history.addComponent(authorLabel);
        history.addComponent(textLabel);
        Timer.delay(scrollToMax, 50);
    }

    public function appendLog(text:String) 
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
}