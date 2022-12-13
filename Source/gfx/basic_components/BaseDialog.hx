package gfx.basic_components;

import gfx.basic_components.utils.DialogGroup;
import gfx.utils.DialogQueue;
import haxe.Timer;
import haxe.ui.events.UIEvent;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.core.Screen as HaxeUIScreen;

abstract class BaseDialog extends Dialog
{
    private var queueCloseCallback:BaseDialog->Void;

    public final group:Null<DialogGroup>;

    private abstract function resize():Void;
    private abstract function onClose(btn:DialogButton):Void;

    private function correctPosition()
    {
        x = (HaxeUIScreen.instance.actualWidth - width) / 2;
        y = (HaxeUIScreen.instance.actualHeight - height) / 2;
    }

    private function correctPositionLater()
    {
        Timer.delay(correctPosition, 60);
    }

    private function onScreenResized() 
    {
        resize();
        correctPosition();
    }

    public override function showDialog(modal:Bool = true)
    {
        super.showDialog(modal);
        SceneManager.addResizeHandler(onScreenResized);
        onScreenResized();
    }

    private function onDialogClosedCallback(event:DialogEvent)
    {
        SceneManager.removeResizeHandler(onScreenResized);
        onClose(event.button);
        queueCloseCallback(this);
    }

    public function assignQueueCallback(queueCloseCallback:BaseDialog->Void)
    {
        this.queueCloseCallback = queueCloseCallback;
    }

    public function new(group:Null<DialogGroup>, modal:Bool) 
    {
        super();
        this.group = group;
        this.modal = modal;

        onDialogClosed = onDialogClosedCallback;
    }
}