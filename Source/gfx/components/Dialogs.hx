package gfx.components;

import gfx.main.ChallengeParamsDialog;
import haxe.ui.components.Image;
import openfl.events.Event;
import utils.AssetManager;
import dict.Phrase;
import haxe.ui.components.OptionBox;
import dict.Dictionary;
import haxe.ui.components.TextField;
import haxe.ui.components.Button;
import struct.PieceColor;
import haxe.ui.containers.HBox;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxe.ui.containers.dialogs.Dialog;
import struct.PieceType;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.containers.dialogs.Dialogs as DialogManager;
import haxe.ui.core.Screen;

class Dialogs
{
    private static var dialogCount:Int = 0;
    private static var activeDialogs:Array<Int> = [];

    public static function hasActive():Bool
    {
        return Lambda.empty(activeDialogs);
    }

    public static function confirm(message:String, title:String, onConfirmed:Void->Void, onDeclined:Void->Void)
    {
        var dialogNum = activeDialogs.push(++dialogCount);
        DialogManager.messageBox(message, title, MessageBoxType.TYPE_QUESTION, true, (btn:DialogButton) -> {
            activeDialogs.remove(dialogNum);
            if (btn == DialogButton.YES)
                onConfirmed();
            else
                onDeclined();
        });
    }

    public static function custom(dialog:Dialog, modal:Bool = true)
    {
        dialog.showDialog(modal);
    }

    public static function alert(message:String, title:String)
    {
        var dialogNum = activeDialogs.push(++dialogCount);
        DialogManager.messageBox(message, title, MessageBoxType.TYPE_WARNING, true, b -> {activeDialogs.remove(dialogNum);});
    }

    public static function info(message:String, title:String)
    {
        var dialogNum = activeDialogs.push(++dialogCount);
        DialogManager.messageBox(message, title, MessageBoxType.TYPE_INFO, true, b -> {activeDialogs.remove(dialogNum);});
    }

    public static function promotionSelect(color:PieceColor, callback:PieceType->Void, onCancel:Void->Void)
    {
        var dialogNum = activeDialogs.push(++dialogCount);

        function cb(dialog:Dialog, type:PieceType) 
        {
            activeDialogs.remove(dialogNum);
            dialog.hideDialog(DialogButton.OK);
            callback(type);
        }

        var dialog:Dialog = new Dialog();
        dialog.width = 430;
        var body:VBox = new VBox();

        var question:Label = new Label();
        question.text = Dictionary.getPhrase(PROMOTION_DIALOG_QUESTION);
        question.width = 430;
        question.textAlign = "center";
        body.addComponent(question);

        var btns:HBox = new HBox();
        for (type in [Aggressor, Liberator, Defensor, Dominator])
            btns.addComponent(pieceBtn(type, color, cb.bind(dialog, type)));
        body.addComponent(btns);

        dialog.addComponent(body);
        dialog.title = Dictionary.getPhrase(PROMOTION_DIALOG_TITLE);
        dialog.buttons = DialogButton.CANCEL;
        dialog.onDialogClosed = (e) -> {
            activeDialogs.remove(dialogNum);
            onCancel();
        };
        dialog.showDialog(false);
    }

    public static function chameleonConfirm(onDecided:Bool->Void, onCancelled:Void->Void)
    {
        var dialogNum = activeDialogs.push(++dialogCount);
        DialogManager.messageBox(Dictionary.getPhrase(CHAMELEON_DIALOG_QUESTION), Dictionary.getPhrase(CHAMELEON_DIALOG_TITLE), MessageBoxType.TYPE_QUESTION, false, (btn:DialogButton) -> {
            activeDialogs.remove(dialogNum);

            if (btn == DialogButton.YES)
                onDecided(true);
            else if (btn == DialogButton.NO)
                onDecided(false);
            else 
                onCancelled();
        });
    }

    public static function specifyChallengeParams(onConfirm:(startSecs:Int, bonusSecs:Int, callerColor:Null<PieceColor>)->Void, onCancel:Void->Void)
    {
        var dialog:Dialog = new ChallengeParamsDialog(onConfirm, onCancel);
        dialog.showDialog(true);
    }

    private static function pieceBtn(type:PieceType, color:PieceColor, callback:Void->Void):Button
    {
        var btn:Button = new Button();
        var bmpData = AssetManager.pieceBitmaps[type][color];

        var scaleMultiplier = 90 / Math.max(bmpData.width, bmpData.height);
        if (type == Progressor)
            scaleMultiplier *= 0.7;
        else if (type == Liberator || type == Defensor)
            scaleMultiplier *= 0.9;

        btn.icon = bmpData;
        btn.width = 100;
        btn.height = 100;

        function resizeIcon(e:Event) 
        {
            btn.removeEventListener(Event.ADDED_TO_STAGE, resizeIcon);
            var imgComponent = btn.findComponent(Image);
            imgComponent.width *= scaleMultiplier;
            imgComponent.height *= scaleMultiplier;
        }

        btn.addEventListener(Event.ADDED_TO_STAGE, resizeIcon);

        btn.onClick = (e) -> {callback();};
        return btn;
    }
}