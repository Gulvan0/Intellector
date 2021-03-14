package;

import haxe.ui.components.Button;
import Figure.FigureColor;
import haxe.ui.containers.HBox;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxe.ui.containers.dialogs.Dialog;
import Figure.FigureType;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.core.Screen;

class Dialogs
{
    public static function confirm(message:String, title:String, onConfirmed:Void->Void, onDeclined:Void->Void)
    {
        Screen.instance.messageBox(message, title, MessageBoxType.TYPE_QUESTION, true, (btn:DialogButton) -> {
            if (btn == DialogButton.YES)
                onConfirmed();
            else
                onDeclined();
        });
    }

    public static function alert(message:String, title:String)
    {
        Screen.instance.messageBox(message, title, MessageBoxType.TYPE_WARNING, true);
    }

    public static function info(message:String, title:String)
    {
        Screen.instance.messageBox(message, title, MessageBoxType.TYPE_INFO, true);
    }

    public static function promotionSelect(color:FigureColor, callback:FigureType->Void, onCancel:Void->Void)
    {
        function cb(dialog:Dialog, type:FigureType) 
        {
            dialog.hideDialog(DialogButton.OK);
            callback(type);
        }

        var dialog:Dialog = new Dialog();
        dialog.width = 430;
        var body:VBox = new VBox();

        var question:Label = new Label();
        question.text = "Select a piece to which you want to promote";
        question.width = 430;
        question.textAlign = "center";
        body.addComponent(question);

        var btns:HBox = new HBox();
        for (type in [Aggressor, Liberator, Defensor, Dominator])
            btns.addComponent(figureBtn(type, color, cb.bind(dialog, type)));
        body.addComponent(btns);

        dialog.addComponent(body);
        dialog.title = "Promotion selection";
        dialog.buttons = DialogButton.CANCEL;
        dialog.onDialogClosed = (e) -> {onCancel();};
        dialog.showDialog(true);
    }

    public static function chameleonConfirm(onConfirmed:Void->Void, onDeclined:Void->Void, onCancelled:Void->Void)
    {
        Screen.instance.messageBox("Morph into an eaten figure?", "Chameleon confirmation", MessageBoxType.TYPE_QUESTION, true, (btn:DialogButton) -> {
            if (btn == DialogButton.YES)
                onConfirmed();
            else if (btn == DialogButton.NO)
                onDeclined();
            else 
                onCancelled();
        });
    }

    private static function figureBtn(type:FigureType, color:FigureColor, callback:Void->Void):Button
    {
        var btn:Button = new Button();
        btn.icon = Figure.pathToImage(type, color, true);
        btn.width = 100;
        btn.height = 100;
        btn.onClick = (e) -> {callback();};
        return btn;
    }
}