package gfx.main;

import haxe.ui.components.Label;
import haxe.ui.components.OptionBox;
import dict.Phrase;
import haxe.ui.components.Button;
import dict.Dictionary;
import haxe.ui.components.TextField;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import struct.PieceColor;
import haxe.ui.containers.dialogs.Dialog;

class ChallengeParamsDialog extends Dialog
{
    private static var CHALLENGE_PARAMS_DIALOG_WIDTH:Float = 300;
    private static var DEFAULT_START_MINS:Int = 10;
    private static var DEFAULT_BONUS_SECS:Int = 5;

    private var callerColor:Null<PieceColor> = null;

    private var baseField:TextField;
    private var incrementField:TextField;

    private var confirmCallback:(startSecs:Int, bonusSecs:Int, callerColor:Null<PieceColor>)->Void;

    private function onConfirmed() 
    {
        var startMins:Int = Std.parseInt(baseField.text);
        var bonusSecs:Int = Std.parseInt(incrementField.text);

        if (startMins > 60 * 5)
            startMins = 300;
        else if (startMins < 1)
            startMins = 1;
        if (bonusSecs > 60)
            bonusSecs = 60;
        else if (bonusSecs < 0)
            bonusSecs = 0;

        hideDialog(DialogButton.OK);
        confirmCallback(startMins*60, bonusSecs, callerColor);
    }

    public function new(onConfirm:(startSecs:Int, bonusSecs:Int, callerColor:Null<PieceColor>)->Void, onCancel:Void->Void) 
    {
        super();
        this.confirmCallback = onConfirm;

        width = CHALLENGE_PARAMS_DIALOG_WIDTH;
        title = Dictionary.getPhrase(CHALLENGE_PARAMS_TITLE);
        onDialogClosed = (e) -> {onCancel();};

        var body:VBox = new VBox();

        body.addComponent(challengeParamLabel(CHOOSE_TIME_CONTROL));
        body.addComponent(timeControlSelection());

        body.addComponent(challengeParamLabel(CHOOSE_COLOR));
        body.addComponent(challengeColorOptionbox(null, true));
        body.addComponent(challengeColorOptionbox(White, false));
        body.addComponent(challengeColorOptionbox(Black, false));

        var btns:HBox = new HBox();
        btns.addComponent(confirmationBtn(CONFIRM, onConfirmed));
        btns.addComponent(confirmationBtn(CANCEL, hideDialog.bind(DialogButton.CANCEL)));
        body.addComponent(btns);

        addComponent(body);
    }
    
    private function timeControlSelection():HBox
    {
        var timeControl:HBox = new HBox();
        timeControl.width = 90;
        timeControl.horizontalAlign = 'center';
        timeControl.x = (CHALLENGE_PARAMS_DIALOG_WIDTH - timeControl.width) / 2;

        baseField = new TextField();
        baseField.width = 30;
        baseField.restrictChars = "0-9";
        baseField.text = "" + DEFAULT_START_MINS;
        timeControl.addComponent(baseField);

        var plusSign:Label = new Label();
        plusSign.text = "+";
        timeControl.addComponent(plusSign);

        incrementField = new TextField();
        incrementField.width = 30;
        incrementField.restrictChars = "0-9";
        incrementField.text = "" + DEFAULT_BONUS_SECS;
        timeControl.addComponent(incrementField);

        return timeControl;
    }

    private function challengeParamLabel(phrase:Phrase):Label 
    {
        var label:Label = new Label();
        label.text = Dictionary.getPhrase(phrase);
        label.width = CHALLENGE_PARAMS_DIALOG_WIDTH;
        label.textAlign = "center";
        label.customStyle = {fontBold: true, fontSize: 14};
        return label;
    }

    private function challengeColorOptionbox(color:Null<PieceColor>, preselected:Bool):OptionBox
    {
        var option:OptionBox = new OptionBox();
		option.text = color == null? Dictionary.getPhrase(COLOR_RANDOM) : Dictionary.getColorName(color);
        option.horizontalAlign = 'center';
        option.componentGroup = "challenge-color";
        option.selected = preselected;

        option.onChange = (e) -> {
			if (option.selected)
                callerColor = color;
        };

        return option;
    }

    private function confirmationBtn(phrase:Phrase, onClick:Void->Void):Button
    {
        var btn:Button = new Button();
        btn.text = Dictionary.getPhrase(phrase);
        btn.width = CHALLENGE_PARAMS_DIALOG_WIDTH / 2 - 8;
        btn.onClick = (e) -> {onClick();};
        return btn;
    }
}