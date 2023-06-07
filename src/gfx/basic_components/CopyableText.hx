package gfx.basic_components;

import browser.Clipboard;
import haxe.Timer;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.HBox;
import js.Browser;
import gfx.Dialogs;
import dict.Dictionary;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/basic_components/copyable_text.xml"))
class CopyableText extends HBox
{
    public var copiedText(get, set):String;

    private function get_copiedText():String
    {
        return tf.text;
    }

    private function set_copiedText(v:String):String
    {
        return tf.text = v;
    }

    @:bind(copyBtn, MouseEvent.CLICK)
    public function onCopySIPPressed(e) 
    {
        Clipboard.copy(tf.text, onCopySuccessful);
    }

    private function onCopySuccessful()
    {
        showTick();
        Timer.delay(showCopy, 500);
    }

    private function showTick()
    {
        tickBtn.hidden = false;
        copyBtn.hidden = true;
    }

    private function showCopy()
    {
        copyBtn.hidden = false;
        tickBtn.hidden = true;
    }

    public function new()
    {
        super();
        showCopy();
    }
}