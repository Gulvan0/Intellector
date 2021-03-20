package;

import haxe.ui.components.TextField;
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
        dialog.showDialog(false);
    }

    public static function chameleonConfirm(onConfirmed:Void->Void, onDeclined:Void->Void, onCancelled:Void->Void)
    {
        Screen.instance.messageBox("Morph into an eaten figure?", "Chameleon confirmation", MessageBoxType.TYPE_QUESTION, false, (btn:DialogButton) -> {
            if (btn == DialogButton.YES)
                onConfirmed();
            else if (btn == DialogButton.NO)
                onDeclined();
            else 
                onCancelled();
        });
    }

    public static function specifyChallengeParams(onConfirm:(startSecs:Int, bonusSecs:Int)->Void, onCancel:Void->Void)
    {
        function cb(dialog:Dialog, startMins:Int, bonusSecs:Int) 
        {
            if (startMins > 60 * 5)
                startMins = 300;
            else if (startMins < 1)
                startMins = 1;

            if (bonusSecs > 60)
                bonusSecs = 60;
            else if (bonusSecs < 0)
                bonusSecs = 0;

            dialog.hideDialog(DialogButton.OK);
            onConfirm(startMins*60, bonusSecs);
        }

        var dialog:Dialog = new Dialog();
        dialog.width = 200;
        var body:VBox = new VBox();

        var question:Label = new Label();
        question.text = "Specify time control for your challenge";
        question.width = 200;
        question.textAlign = "center";
        body.addComponent(question);

        var timeControl:HBox = new HBox();
        timeControl.width = 90;
        timeControl.x = (dialog.width - timeControl.width) / 2;

        var baseField:TextField = new TextField();
        baseField.width = 30;
        baseField.restrictChars = "0-9";
        timeControl.addComponent(baseField);

        var plusSign:Label = new Label();
        plusSign.text = "+";
        timeControl.addComponent(plusSign);

        var incrementField:TextField = new TextField();
        incrementField.width = 30;
        incrementField.restrictChars = "0-9";
        timeControl.addComponent(incrementField);

        timeControl.horizontalAlign = 'center';
        body.addComponent(timeControl);

        var btns:HBox = new HBox();

        var confirmBtn:Button = new Button();
        confirmBtn.text = "Confirm";
        confirmBtn.width = 92;
        confirmBtn.onClick = (e) -> {cb(dialog, Std.parseInt(baseField.text), Std.parseInt(incrementField.text));};
        btns.addComponent(confirmBtn);

        var cancelBtn:Button = new Button();
        cancelBtn.text = "Cancel";
        cancelBtn.width = 92;
        cancelBtn.onClick = (e) -> {onCancel();};
        btns.addComponent(cancelBtn);

        body.addComponent(btns);

        dialog.addComponent(body);
        dialog.title = "Challenge parameters";
        dialog.onDialogClosed = (e) -> {onCancel();};
        dialog.showDialog(true);
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