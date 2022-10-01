package gfx.basic_components;

import haxe.ui.util.ImageLoader;
import haxe.Timer;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.HBox;
import js.Browser;
import gfx.Dialogs;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/basic_components/copyable_text.xml"))
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
        Browser.navigator.clipboard.writeText(tf.text)
            .catchError(onCopyError)
            .finally(onCopySuccessful);
    }

    private function onCopyError(e)
    {
        Dialogs.alert(CLIPBOARD_ERROR_ALERT_TEXT, CLIPBOARD_ERROR_ALERT_TITLE, ['$e']);
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