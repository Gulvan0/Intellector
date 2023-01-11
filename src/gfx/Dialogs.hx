package gfx;

import dict.Dictionary;
import dict.Phrase;
import gfx.basic_components.utils.DialogGroup;
import gfx.utils.DialogQueue;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialogs as DialogManager;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import js.Browser;

enum SpaceRemoval
{
    None;
    Trim;
    All;
}

class Dialogs
{
    private static var queue:DialogQueue = new DialogQueue();

    public static function getQueue():DialogQueue
    {
        return queue;
    }

    public static function alertRaw(message:String, ?title:String = "Raw alert")
    {
        queue.addBasic(DialogManager.messageBox(message, title, MessageBoxType.TYPE_WARNING, true));
    }

    public static function alert(message:Phrase, title:Phrase, ?messageSubstitutions:Array<String>)
    {
        var messageStr:String = Dictionary.getPhrase(message, messageSubstitutions);
        var titleStr:String = Dictionary.getPhrase(title);
        alertRaw(messageStr, titleStr);
    }

    public static function alertCallback(message:Phrase, title:Phrase, ?messageSubstitutions:Array<String>):Void->Void 
    {
        return alert.bind(message, title, messageSubstitutions);
    }

    public static function infoRaw(message:String, title:String, ?group:Null<DialogGroup>)
    {
        queue.addBasic(DialogManager.messageBox(message, title, MessageBoxType.TYPE_INFO, true), null, false, group);
    }

    public static function info(message:Phrase, title:Phrase, ?messageSubstitutions:Array<String>, ?group:Null<DialogGroup>)
    {
        infoRaw(Dictionary.getPhrase(message, messageSubstitutions), Dictionary.getPhrase(title), group);
    }

    public static function confirmRaw(message:String, title:String, onConfirmed:Void->Void, onDeclined:Void->Void)
    {
        var dialog = DialogManager.messageBox(message, title, MessageBoxType.TYPE_QUESTION, true);

        queue.addBasic(dialog, btn -> {
            if (btn == DialogButton.YES)
                onConfirmed();
            else
                onDeclined();
        });
    }

    public static function confirm(message:Phrase, title:Phrase, onConfirmed:Void->Void, onDeclined:Void->Void)
    {
        confirmRaw(Dictionary.getPhrase(message), Dictionary.getPhrase(title), onConfirmed, onDeclined);
    }

    public static function prompt(message:Phrase, removeSpaces:SpaceRemoval, onInput:String->Void, ?onCancel:Null<Void->Void>, ?emptyIsCancel:Bool = true) 
    {
        var res:Null<String> = Browser.window.prompt(Dictionary.getPhrase(message));

        if (res == null)
        {
            if (onCancel != null)
                onCancel();
            return;
        }

        if (removeSpaces == Trim)
            res = StringTools.trim(res);
        else if (removeSpaces == All)
            res = StringTools.replace(res, ' ', '');

        if (res == "" && emptyIsCancel)
            onCancel();
        else
            onInput(res);
    }
}