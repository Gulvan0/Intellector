package tests.ui.utils.components;

import haxe.exceptions.NotImplementedException;
import gfx.components.BoardWrapper;
import struct.Situation;
import gameboard.SelectableBoard;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxe.ui.components.Button;
import haxe.ui.components.TextField;
import tests.ui.utils.data.EndpointArgument;
import haxe.ui.containers.HBox;
import tests.ui.utils.data.ActionEndpointPrompt;
import haxe.ui.containers.dialogs.Dialog;

class ActionPromptDialog extends Dialog
{
    private var prompts:Array<ActionEndpointPrompt>;
    private var currentSituation:Situation;

    private var inputTextfields:Map<String, TextField> = [];
    private var inputBoards:Map<String, SelectableBoard> = [];

    private function retrieveArguments():Array<EndpointArgument>
    {
        //TODO: Fill
        throw new NotImplementedException();
    }

    private function onConfirmPressed(e)
    {
        //TODO: Fill
    }

    private function constructDefaultValuesBox(defaultValues:Array<EndpointArgument>, inputTextfield:TextField):HBox
    {
        var hbox:HBox = new HBox();
        hbox.percentWidth = 100;

        var btnPercentWidth:Float = 100 / defaultValues.length;
        for (arg in defaultValues)
        {
            var btn:Button = new Button();
            btn.text = arg.getDisplayText(currentSituation);
            btn.percentWidth = btnPercentWidth;
            btn.onClick = e -> {inputTextfield.text = btn.text;};
            hbox.addComponent(btn);
        }

        return hbox;
    }

    private function constructNormalInput(prompt:ActionEndpointPrompt):VBox
    {
        var label:Label = new Label();
        label.text = prompt.displayName + ":";
        label.customStyle = {fontSize: 24};

        var inputField:TextField = new TextField();
        inputField.percentWidth = 100;
        inputField.height = 25;

        if (prompt.type == AInt)
            inputField.restrictChars = "0-9";
        else if (prompt.type == AFloat)
            inputField.restrictChars = "0-9.";

        inputTextfields.set(prompt.displayName, inputField);
        
        var inputRow:HBox = new HBox();
        inputRow.percentWidth = 100;
        inputRow.addComponent(label);
        inputRow.addComponent(inputField);

        var defaultValuesRow:HBox = constructDefaultValuesBox(prompt.defaultValues, inputField);

        var vbox:VBox = new VBox();
        vbox.addComponent(inputRow);
        vbox.addComponent(defaultValuesRow);
        return vbox;
    }

    private function constructPlyInput(prompt:ActionEndpointPrompt, totalPlyInputs:Int):VBox
    {
        var label:Label = new Label();
        label.percentWidth = 100;
        label.text = prompt.displayName + ":";
        label.customStyle = {fontSize: 24};

        var inputBoard:SelectableBoard = new SelectableBoard(currentSituation, EnsureSingle, Disabled);
        var boardWrapper:BoardWrapper = new BoardWrapper(inputBoard);
        boardWrapper.percentHeight = 100 / totalPlyInputs; //TODO: Ensure fitting

        inputBoards.set(prompt.displayName, inputBoard);

        var defaultValuesRow:HBox = constructDefaultValuesBox(prompt.defaultValues, inputField);

        var vbox:VBox = new VBox();
        vbox.addComponent(label);
        vbox.addComponent(boardWrapper);
        vbox.addComponent(defaultValuesRow);
        return vbox;
    }

    public function new(prompts:Array<ActionEndpointPrompt>, currentSituation:Situation) 
    {
        super();
        percentWidth = 75;
        percentHeight = 90;

        var totalPlyPrompts:Int = 0;
        for (prompt in prompts)
            if (prompt.type == APly)
                totalPlyPrompts++;

        for (prompt in prompts)
        {
            if (prompt.type == APly)
                addComponent(constructPlyInput(prompt, totalPlyPrompts));
            else 
                addComponent(constructNormalInput(prompt));
        }

        var confirmBtn:Button = new Button();
        confirmBtn.text = "Confirm";
        confirmBtn.percentWidth = 100;
        confirmBtn.onClick = onConfirmPressed;
        addComponent(confirmBtn); //TODO: Use built-in button
    }
}