package tests.ui.utils.components;

import haxe.ui.containers.HorizontalButtonBar;
import haxe.ui.containers.ButtonBar;
import haxe.ui.components.Button;
import haxe.Constraints.Function;
import tests.ui.utils.data.EndpointArgument;
import tests.ui.utils.data.ActionEndpointPrompt;
import tests.ui.utils.data.TestCaseInfo;
import tests.ui.FieldTraverser.FieldTraverserResults;
import struct.Situation;
import haxe.Timer;
import haxe.ui.components.Label;
import tests.ui.utils.data.MaterializedInitParameter;
import haxe.ui.events.MouseEvent;
import gameboard.SelectableBoard;
import gfx.components.BoardWrapper;
import tests.ui.utils.data.MacroStep;
import haxe.ui.containers.HBox;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/testenv/main.xml"))
class MainView extends HBox
{
    private var currentTestCase:String;
    private var component:TestedComponent;

    private var initParams:Array<MaterializedInitParameter<Dynamic>>;
    private var initParamEntries:Map<String, InitParameterEntry>;

    private var actionEndpointPrompts:Map<String, Array<ActionEndpointPrompt>> = [];

    private var board:SelectableBoard;

    public function appendToHistory(step:MacroStep)
    {
        var stepStr = switch step 
        {
            case EndpointCall(endpointName, arguments): endpointName + '(' + [for (arg in arguments) arg.asString()].join(', ') + ')';
            case Event(serializedEvent): serializedEvent;
        }
        var label:Label = new Label();
        label.text = stepStr;
        historyVBox.addComponent(label);
    }

    @:bind(initializeBtn, MouseEvent.CLICK)
    private function reinitializeComponent(e)
    {
        for (parameter in initParams)
        {
            var selectedIndex:Int = initParamEntries[parameter.identifier].getSelected();
            var selectedValue:Dynamic = parameter.possibleValues[selectedIndex];
            Reflect.setField(component, parameter.fieldName, selectedValue);
        }

        component.update();
    }

    @:bind(traceStateBtn, MouseEvent.CLICK)
    private function traceComponentState(e)
    {
        trace(component);
    }

    @:bind(addMacroLink, MouseEvent.CLICK)
    private function addMacro(e)
    {
        //TODO: Fill
    }

    @:bind(proposeMacrosBtn, MouseEvent.CLICK)
    private function proposeMacros(e)
    {
        var untrackedMacroNames = DataKeeper.getUntrackedMacroNames(currentTestCase);
        var dialog = new ProposeMacrosDialog(untrackedMacroNames, currentTestCase);
        dialog.showDialog();
    }

    private function timerRun()
    {
        board.setSituation(component._provide_situation());
    }

    private function onActionBtnPressed(fieldName:String, ?splitterValue:String)
    {
        var dialog:ActionPromptDialog = new ActionPromptDialog(actionEndpointPrompts.get(fieldName), component._provide_situation(), promptArgs -> {
            var args:Array<EndpointArgument> = promptArgs;
            if (splitterValue != null)
                args.unshift(new EndpointArgument(AString, splitterValue));

            UITest.logEndpointCall(fieldName, args);
            Reflect.callMethod(component, getMethod(fieldName), args.map(x -> x.value));
        });
        dialog.showDialog();
    }

    private function onSequenceStep(fieldName:String, step:Int)
    {
        var endpointArgs:Array<EndpointArgument> = [new EndpointArgument(AInt, step)];
        UITest.logEndpointCall(fieldName, endpointArgs);
        Reflect.callMethod(component, getMethod(fieldName), [step]);
    }

    private function onMacroStep(step:MacroStep) 
    {
        UITest.logStep(step);
        switch step 
        {
            case EndpointCall(endpointName, arguments):
                Reflect.callMethod(component, getMethod(endpointName), arguments.map(x -> x.value));
            case Event(serializedEvent):
                component._imitateEvent(serializedEvent);
        }
    }

    private function getMethod(fieldName:String):Function 
    {
        var method = Reflect.field(component, fieldName);
        if (method == null)
            throw 'Field not found: $fieldName, test case: $currentTestCase';
        else if (!Reflect.isFunction(method))
            throw 'Field is not a function: $fieldName, test case: $currentTestCase';
        else
            return method;
    }

    public function new(component:TestedComponent, fieldData:FieldTraverserResults, storedData:TestCaseInfo)
    {
        super();
        this.currentTestCase = Type.getClassName(Type.getClass(component));
        this.component = component;
        this.initParams = fieldData.initParameters;

        testedComponentBox.addComponent(component);

        componentNameLabel.htmlText = 'Component: <u>$currentTestCase</u>';

        for (param in initParams)
        {
            var paramEntry:InitParameterEntry = new InitParameterEntry(param.displayName, param.labels);
            initParamEntries.set(param.identifier, paramEntry);
            initParamsVBox.addComponent(paramEntry);
        }

        for (endpoint in fieldData.endpoints)
        {
            switch endpoint 
            {
                case Action(fieldName, displayName, splitterValues, prompts):
                    actionEndpointPrompts.set(fieldName, prompts);
                    if (splitterValues == null)
                    {
                        var btn:Button = new Button();
                        btn.percentWidth = 100;
                        btn.text = displayName;
                        btn.onClick = e -> {onActionBtnPressed(fieldName);};
                        actionsVBox.addComponent(btn);
                    }
                    else
                    {
                        var buttonBar:ButtonBar = new HorizontalButtonBar();
                        buttonBar.percentWidth = 100;
                        buttonBar.toggle = false;
                        for (splitterValue in splitterValues)
                        {
                            var btn:Button = new Button();
                            btn.percentWidth = 100 / splitterValues.length;
                            btn.text = splitterValue;
                            btn.onClick = e -> {onActionBtnPressed(fieldName, splitterValue);};
                            buttonBar.addComponent(btn);
                        }
                        actionsVBox.addComponent(buttonBar);
                    }
                case Sequence(fieldName, displayName, iterations):
                    var widget:SequenceWidget = new SequenceWidget(displayName, iterations, false, onSequenceStep.bind(fieldName));
                    sequencesVBox.addComponent(widget);
            }
        }

        for (storedMacro in storedData.descriptor.allMacros())
        {
            var callback:Int->Void = step -> {
                var macroStep:MacroStep = storedMacro.getStep(step);
                onMacroStep(macroStep);
            };
            var widget:SequenceWidget = new SequenceWidget(storedMacro.name, storedMacro.totalSteps(), false, callback);
            sequencesVBox.addComponent(widget);
        }

        //TODO: Add & Bind Checks

        board = new SelectableBoard(Situation.starting(), Disabled, Disabled);
        var boardWrapper:BoardWrapper = new BoardWrapper(board);
        boardWrapper.percentWidth = 100;
        boardWrapper.maxPercentHeight = 100;
        boardContainer.addComponent(boardWrapper);

        var timer:Timer = new Timer(1000);
        timer.run = timerRun;
    }
}