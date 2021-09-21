package gfx.components;

import utils.AssetManager;
import gfx.components.main.ChallengeParamsDialog;
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
    public static function confirm(message:String, title:String, onConfirmed:Void->Void, onDeclined:Void->Void)
    {
        DialogManager.messageBox(message, title, MessageBoxType.TYPE_QUESTION, true, (btn:DialogButton) -> {
            if (btn == DialogButton.YES)
                onConfirmed();
            else
                onDeclined();
        });
    }

    public static function alert(message:String, title:String)
    {
        DialogManager.messageBox(message, title, MessageBoxType.TYPE_WARNING, true);
    }

    public static function info(message:String, title:String)
    {
        DialogManager.messageBox(message, title, MessageBoxType.TYPE_INFO, true);
    }

    public static function promotionSelect(color:PieceColor, callback:PieceType->Void, onCancel:Void->Void)
    {
        function cb(dialog:Dialog, type:PieceType) 
        {
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
            btns.addComponent(figureBtn(type, color, cb.bind(dialog, type)));
        body.addComponent(btns);

        dialog.addComponent(body);
        dialog.title = Dictionary.getPhrase(PROMOTION_DIALOG_TITLE);
        dialog.buttons = DialogButton.CANCEL;
        dialog.onDialogClosed = (e) -> {onCancel();};
        dialog.showDialog(false);
    }

    public static function chameleonConfirm(onConfirmed:Void->Void, onDeclined:Void->Void, onCancelled:Void->Void)
    {
        DialogManager.messageBox(Dictionary.getPhrase(CHAMELEON_DIALOG_QUESTION), Dictionary.getPhrase(CHAMELEON_DIALOG_TITLE), MessageBoxType.TYPE_QUESTION, false, (btn:DialogButton) -> {
            if (btn == DialogButton.YES)
                onConfirmed();
            else if (btn == DialogButton.NO)
                onDeclined();
            else 
                onCancelled();
        });
    }

    public static function specifyChallengeParams(onConfirm:(startSecs:Int, bonusSecs:Int, callerColor:Null<PieceColor>)->Void, onCancel:Void->Void)
    {
        var dialog:Dialog = new ChallengeParamsDialog(onConfirm, onCancel);
        dialog.showDialog(true);
    }

    private static function figureBtn(type:PieceType, color:PieceColor, callback:Void->Void):Button
    {
        var btn:Button = new Button();
        btn.icon = AssetManager.pathToImage(type, color, true);
        btn.width = 100;
        btn.height = 100;
        btn.onClick = (e) -> {callback();};
        return btn;
    }
}