package gfx.basic_components;

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
    @:bind(copyBtnTick, MouseEvent.CLICK)
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
        Timer.delay(hideTick, 500);
    }

    private function showTick()
    {
        copyBtn.hidden = true;
        copyBtnTick.hidden = false;
    }

    private function hideTick()
    {
        copyBtn.hidden = false;
        copyBtnTick.hidden = true;
    }
}