package gfx;

import gfx.basic_components.utils.DialogGroup;
import gfx.utils.DialogQueue;
import net.shared.dataobj.ChallengeData;
import gfx.popups.OpenChallengeCreated;
import gfx.popups.StudyParamsDialog;
import gfx.profile.complex_components.MiniProfile;
import gfx.popups.IncomingChallengeDialog;
import gfx.popups.ChangelogDialog;
import gfx.popups.ChallengeParamsDialog;
import struct.ChallengeParams;
import haxe.ui.containers.Box;
import openfl.Assets;
import js.Browser;
import gfx.popups.LogIn;
import gfx.popups.Settings;
import haxe.ui.containers.ScrollView;
import utils.Changelog;
import haxe.ui.containers.dialogs.MessageBox;
import haxe.Timer;
import haxe.ui.util.Variant;
import openfl.display.Shape;
import gameboard.Piece;
import haxe.ui.components.Image;
import openfl.events.Event;
import utils.AssetManager;
import dict.Phrase;
import haxe.ui.components.OptionBox;
import dict.Dictionary;
import haxe.ui.components.TextField;
import haxe.ui.components.Button;
import net.shared.PieceColor;
import haxe.ui.containers.HBox;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxe.ui.containers.dialogs.Dialog;
import net.shared.PieceType;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.containers.dialogs.Dialogs as DialogManager;
import haxe.ui.core.Screen;
import gfx.basic_components.SpriteWrapper;
import net.shared.dataobj.MiniProfileData;

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