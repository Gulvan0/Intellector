package tests.ui.utils.components;

import struct.Ply;
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
    private var onConfirmed:Array<EndpointArgument>->Void;
    private var prompts:Array<ActionEndpointPrompt>;
    private var currentSituation:Situation;

    private var inputTextfields:Map<String, TextField> = [];
    private var inputBoards:Map<String, SelectableBoard> = [];

    private function retrieveArguments():Null<Array<EndpointArgument>>
    {
        var arguments:Array<EndpointArgument> = [];
        for (prompt in prompts)
        {
            switch prompt.type 
            {
                case AInt:
                    var inputTextfield = inputTextfields.get(prompt.displayName);
                    if (inputTextfield == null)
                        throw 'inputTextfields has no mapping for prompt ${prompt.displayName}';
                    else 
                    {
                        var value = Std.parseInt(inputTextfield.text);
                        if (value == null)
                            return null;
                        else
                            arguments.push(new EndpointArgument(prompt.type, value));  
                    }                  
                case AFloat:
                    var inputTextfield = inputTextfields.get(prompt.displayName);
                    if (inputTextfield == null)
                        throw 'inputTextfields has no mapping for prompt ${prompt.displayName}';
                    else 
                    {
                        var value = Std.parseFloat(inputTextfield.text);
                        if (value == null)
                            return null;
                        else
                            arguments.push(new EndpointArgument(prompt.type, value));  
                    }   
                case AString, AEnumerable:
                    var inputTextfield = inputTextfields.get(prompt.displayName);
                    if (inputTextfield == null)
                        throw 'inputTextfields has no mapping for prompt ${prompt.displayName}';
                    else
                        arguments.push(new EndpointArgument(prompt.type, inputTextfield.text));
                case APly:
                    var inputBoard = inputBoards.get(prompt.displayName);
                    if (inputBoard == null)
                        throw 'inputTextfields has no mapping for prompt ${prompt.displayName}';
                    else 
                    {
                        var value = inputBoard.getAnyDrawnArrow();
                        if (value == null)
                            return null;
                        else
                            arguments.push(new EndpointArgument(prompt.type, Ply.construct(value.from, value.to)));  //TODO: Enable chameleon
                    }   
            }
        }

        return arguments;
    }

    private function constructDefaultValuesBox(prompt:ActionEndpointPrompt):HBox
    {
        var promptKey:String = prompt.displayName;

        var hbox:HBox = new HBox();
        hbox.percentWidth = 100;

        var btnPercentWidth:Float = 100 / prompt.defaultValues.length;
        for (arg in prompt.defaultValues)
        {
            var btn:Button = new Button();
            btn.text = arg.getDisplayText(currentSituation);
            btn.percentWidth = btnPercentWidth;
            btn.onClick = e -> {
                if (prompt.type == APly)
                    if (inputBoards.exists(promptKey))
                    {
                        var ply:Ply = cast(arg.value, Ply);
                        inputBoards.get(promptKey).drawArrow(ply.from, ply.to);
                    }
                    else
                        throw 'inputBoards has no mapping for prompt $promptKey';
                else
                    if (inputTextfields.exists(promptKey))
                        inputTextfields.get(promptKey).text = btn.text;
                    else
                        throw 'inputTextfields has no mapping for prompt $promptKey';
            };
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

        var defaultValuesRow:HBox = constructDefaultValuesBox(prompt);

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
        boardWrapper.maxPercentWidth = 100;
        boardWrapper.percentHeight = 100 / totalPlyInputs;

        inputBoards.set(prompt.displayName, inputBoard);

        var defaultValuesRow:HBox = constructDefaultValuesBox(prompt);

        var vbox:VBox = new VBox();
        vbox.addComponent(label);
        vbox.addComponent(boardWrapper);
        vbox.addComponent(defaultValuesRow);
        return vbox;
    }

    public function new(prompts:Array<ActionEndpointPrompt>, currentSituation:Situation, onConfirmed:Array<EndpointArgument>->Void) 
    {
        super();
        this.onConfirmed = onConfirmed;
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

        buttons = DialogButton.APPLY;

        onDialogClosed = e -> {
            if (e.button == DialogButton.APPLY)
            {
                var args = retrieveArguments();
                if (args != null)
                    onConfirmed(args);
                else 
                    trace("Failed to collect arguments: some values are not provided");
            }
                
        }
    }
}