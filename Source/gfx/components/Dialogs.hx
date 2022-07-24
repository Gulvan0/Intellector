package gfx.components;

import haxe.ui.containers.dialogs.MessageBox;
import haxe.Timer;
import haxe.ui.util.Variant;
import openfl.display.Shape;
import gameboard.Piece;
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
    public static var dialogActive:Bool = false;

    public static function confirm(message:String, title:String, onConfirmed:Void->Void, onDeclined:Void->Void)
    {
        dialogActive = true;
        DialogManager.messageBox(message, title, MessageBoxType.TYPE_QUESTION, true, (btn:DialogButton) -> {
            dialogActive = false;
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
        dialogActive = true;
        DialogManager.messageBox(message, title, MessageBoxType.TYPE_WARNING, true)
            .onDialogClosed = e -> {dialogActive = false;};

    }

    public static function info(message:String, title:String)
    {
        dialogActive = true;
        DialogManager.messageBox(message, title, MessageBoxType.TYPE_INFO, true)
            .onDialogClosed = e -> {dialogActive = false;};
    }

    public static function branchingHelp()
    {
        dialogActive = true;

        var messageBox = new MessageBox();
        messageBox.type = MessageBoxType.TYPE_INFO;
        messageBox.title = Dictionary.getPhrase(ANALYSIS_BRANCHING_HELP_DIALOG_TITLE);
        messageBox.messageLabel.htmlText = Dictionary.getPhrase(ANALYSIS_BRANCHING_HELP_DIALOG_TEXT);
        messageBox.messageLabel.customStyle = {fontSize: Math.max(Screen.instance.height * 0.02, 12)};
        messageBox.width = Math.min(500, Screen.instance.width * 0.95);
        messageBox.onDialogClosed = e -> {dialogActive = false;};
        messageBox.showDialog(true);
    }

    public static function promotionSelect(color:PieceColor, callback:PieceType->Void)
    {
        dialogActive = true;
        
        function cb(dialog:Dialog, type:PieceType) 
        {
            dialog.hideDialog(DialogButton.OK);
            callback(type);
        }

        var dialog:Dialog = new Dialog();
        var body:VBox = new VBox();

        var question:Label = new Label();
        question.text = Dictionary.getPhrase(PROMOTION_DIALOG_QUESTION);
        question.textAlign = "center";
        body.addComponent(question);

        var btns:HBox = new HBox();
        btns.horizontalAlign = 'center';
        for (type in [Aggressor, Liberator, Defensor, Dominator])
            btns.addComponent(pieceBtn(type, color, cb.bind(dialog, type)));
        body.addComponent(btns);

        dialog.addComponent(body);
        dialog.title = Dictionary.getPhrase(PROMOTION_DIALOG_TITLE);
        dialog.buttons = DialogButton.CANCEL;
        dialog.onDialogClosed = e -> {dialogActive = false;};
        dialog.showDialog(false);
    }

    public static function chameleonConfirm(onDecided:Bool->Void)
    {
        dialogActive = true;
        DialogManager.messageBox(Dictionary.getPhrase(CHAMELEON_DIALOG_QUESTION), Dictionary.getPhrase(CHAMELEON_DIALOG_TITLE), MessageBoxType.TYPE_QUESTION, false, (btn:DialogButton) -> {
            if (btn == DialogButton.YES)
                onDecided(true);
            else if (btn == DialogButton.NO)
                onDecided(false);
        })
            .onDialogClosed = e -> {dialogActive = false;};
    }

    public static function specifyChallengeParams(onConfirm:(startSecs:Int, bonusSecs:Int, callerColor:Null<PieceColor>)->Void, onCancel:Void->Void)
    {
        var dialog:Dialog = new ChallengeParamsDialog(onConfirm, onCancel);
        dialog.showDialog(true);
    }

    private static function onBtnAdded(btn:Button, type:PieceType, color:PieceColor, iconSize:Float, e) 
    {
        var icon:Image = btn.findComponent(Image);
        switch type 
        {
            case Progressor:
                icon.width = Piece.pieceRelativeScale(Progressor) * iconSize;
                icon.height = icon.width / Piece.pieceAspectRatio(Progressor, color);
            default:
                icon.height = Piece.pieceRelativeScale(type) * iconSize;
                icon.width = icon.height * Piece.pieceAspectRatio(type, color);
        }
    }

    private static function pieceBtn(type:PieceType, color:PieceColor, callback:Void->Void):Button
    {
        var btnSize:Float = Math.min(100, Math.min(Screen.instance.height * 0.5, Screen.instance.width * 0.2));

        var btn:Button = new Button();
        btn.icon = AssetManager.piecePath(type, color);
        btn.width = btnSize;
        btn.height = btnSize;
        btn.addEventListener(Event.ADDED_TO_STAGE, onBtnAdded.bind(btn, type, color, 0.8 * btnSize));
        btn.onClick = (e) -> {callback();};
        return btn;
    }
}