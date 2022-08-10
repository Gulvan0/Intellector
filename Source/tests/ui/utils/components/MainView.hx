package tests.ui.utils.components;

import js.Cookie;
import gfx.components.Dialogs;
import tests.ui.utils.data.Macro;
import utils.StringUtils;
import haxe.ui.core.Screen;
import haxe.ui.containers.VBox;
import haxe.exceptions.NotImplementedException;
import haxe.Json;
import haxe.Serializer;
import haxe.ui.components.CheckBox;
import haxe.ui.components.SectionHeader;
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
    private var component:TestedComponent;

    private var initParams:Array<MaterializedInitParameter<Dynamic>>;

    private var initParamEntries:Map<String, InitParameterEntry> = [];
    private var actionEndpointPrompts:Map<String, Array<ActionEndpointPrompt>> = [];

    private var board:SelectableBoard;

    public function appendToHistory(step:MacroStep)
    {
        var label:Label = new Label();
        label.text = macroStepDisplayText(step);
        historyVBox.addComponent(label);
    }

    @:bind(initializeBtn, MouseEvent.CLICK)
    private function reinitializeComponent(e)
    {
        var paramValueIndexes:Map<String, Int> = [];

        for (parameter in initParams)
        {
            var selectedIndex:Int = initParamEntries[parameter.identifier].getSelected();
            var selectedValue:Dynamic = parameter.possibleValues[selectedIndex];
            Reflect.setField(component, parameter.fieldName, selectedValue);
            paramValueIndexes.set(parameter.identifier, selectedIndex);
        }

        component.update();

        //If we call it manually, therefore, e is null, we have logged the step already previously in onMacroStep()
        if (e != null)
            UITest.logStep(Initialization(paramValueIndexes));
    }

    @:bind(traceStateBtn, MouseEvent.CLICK)
    private function traceComponentState(e)
    {
        throw new NotImplementedException();
    }

    @:bind(addMacroLink, MouseEvent.CLICK)
    private function addMacro(e)
    {
        if (!Lambda.empty(UITest.getHistory()))
            new AddMacroDialog(addMacroWidget.bind(_, false)).showDialog(true);
        else
            Dialogs.alert("History is empty", "TestEnv Warning");
    }

    @:bind(proposeMacrosBtn, MouseEvent.CLICK)
    private function proposeMacros(e)
    {
        var untrackedMacroNames = DataKeeper.getUntrackedMacroNames();

        if (!Lambda.empty(untrackedMacroNames))
            new ProposeMacrosDialog(untrackedMacroNames).showDialog(true);
        else
            Dialogs.alert("No untracked macros detected", "TestEnv Warning");
    }

    private function timerRun()
    {
        board.setShownSituation(component._provide_situation());
    }

    private function onActionBtnPressed(fieldName:String, ?splitterValue:String)
    {
        var prompts = actionEndpointPrompts.get(fieldName);
        if (Lambda.empty(prompts))
        {
            if (splitterValue != null)
            {
                UITest.logEndpointCall(fieldName, [new EndpointArgument(AString, splitterValue)]);
                Reflect.callMethod(component, getMethod(fieldName), [splitterValue]);
            }
            else
            {
                UITest.logEndpointCall(fieldName, []);
                Reflect.callMethod(component, getMethod(fieldName), []);
            }
            return;
        }

        var dialog:ActionPromptDialog = new ActionPromptDialog(prompts, component._provide_situation(), promptArgs -> {
            var args:Array<EndpointArgument> = promptArgs;
            if (splitterValue != null)
                args.unshift(new EndpointArgument(AString, splitterValue));

            UITest.logEndpointCall(fieldName, args);
            Reflect.callMethod(component, getMethod(fieldName), args.map(x -> x.value));
            component.onDialogHidden();
        });
        component.onDialogShown();
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
                component.imitateEvent(serializedEvent);
            case Initialization(paramValueIndexes):
                for (parameter in initParams)
                {
                    var selectedIndex:Int = paramValueIndexes[parameter.identifier];
                    initParamEntries[parameter.identifier].setSelected(selectedIndex);
                }
                reinitializeComponent(null);
        }
    }

    private function getMethod(fieldName:String):Function 
    {
        var method = Reflect.field(component, fieldName);
        if (method == null)
            throw 'Field not found: $fieldName';
        else if (!Reflect.isFunction(method))
            throw 'Field is not a function: $fieldName';
        else
            return method;
    }

    private function addMacroWidget(m:Macro, ?immutable:Bool = true)
    {
        var stepCallback:Int->Void = step -> {
            var macroStep:MacroStep = m.getStep(step);
            onMacroStep(macroStep);
        };

        var widget:SequenceWidget = new SequenceWidget(m.name, m.totalSteps(), stepCallback);

        var removeCallback = () -> {
            DataKeeper.getCurrent().descriptor.removeMacro(m);
            sequencesVBox.removeComponent(widget);
        };

        var renameCallback = (newName:String) -> {
            DataKeeper.getCurrent().descriptor.renameMacro(m, newName);
        };
        
        if (!immutable)
            widget.makeEditable(removeCallback, renameCallback);

        sequencesVBox.addComponent(widget);
    }

    public function new(component:TestedComponent, fieldData:FieldTraverserResults, storedData:TestCaseInfo)
    {
        super();
        this.component = component;
        this.initParams = fieldData.initParameters;

        testedComponentBox.addComponent(component);

        componentNameLabel.htmlText = '<b>Test Case: <i>${UITest.getCurrentTestCase()}</i></b>';

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
                        actionsVBox.addComponent(SimpleComponents.fullActionBtn(displayName, onActionBtnPressed.bind(fieldName)));
                    else
                    {
                        var buttonBar:ButtonBar = new HorizontalButtonBar();
                        buttonBar.percentWidth = 100;
                        buttonBar.toggle = false;
                        for (splitterValue in splitterValues)
                            buttonBar.addComponent(SimpleComponents.splittedActionBtn(splitterValue, splitterValues.length, onActionBtnPressed.bind(fieldName, _)));
                        actionsVBox.addComponent(buttonBar);
                    }
                case Sequence(fieldName, displayName, iterations):
                    var widget:SequenceWidget = new SequenceWidget(displayName, iterations, onSequenceStep.bind(fieldName));
                    sequencesVBox.addComponent(widget);
            }
        }

        for (storedMacro in storedData.descriptor.allMacros())
            addMacroWidget(storedMacro);

        if (Cookie.exists("_" + UITest.getCurrentTestCase()))
        {
            var shortTermMacrosStr:String = Cookie.get("_" + UITest.getCurrentTestCase());
            var currentIndex:Int = 0;

            while (currentIndex < shortTermMacrosStr.length)
            {
                var lbIndex:Int = shortTermMacrosStr.indexOf('[', currentIndex);
                var rbIndex:Int = shortTermMacrosStr.indexOf(']', lbIndex+1);
                var m:Macro = Macro.compactDeserialize(shortTermMacrosStr.substring(currentIndex, lbIndex), shortTermMacrosStr.substring(lbIndex+1, rbIndex));
                DataKeeper.getCurrent().descriptor.addMacro(m, false);
                addMacroWidget(m, false);
                currentIndex = rbIndex + 1;
            }
        }

        for (moduleName => checkModule in storedData.descriptor.checks)
        {
            var header:SectionHeader = new SectionHeader();
            header.text = StringUtils.asPhrase(moduleName);
            checksVBox.addComponent(header);

            switch checkModule 
            {
                case Normal(checklist):
                    for (check in checklist)
                        checksVBox.addComponent(SimpleComponents.checkbox(moduleName, check, storedData));
                case Stepwise(checks):
                    for (check in checks.commonChecks)
                        checksVBox.addComponent(SimpleComponents.checkbox(moduleName, check, storedData));
                    for (step in checks.checkedStepsOrdered)
                    {
                        var stepHeader:Label = new Label();
                        stepHeader.text = 'Step $step';
                        stepHeader.customStyle = {fontItalic: true};
                        checksVBox.addComponent(stepHeader);

                        for (check in checks.stepChecks.get(step))
                            checksVBox.addComponent(SimpleComponents.checkbox(moduleName, check, storedData));
                    }
            }
        }

        board = new SelectableBoard(Situation.starting(), Disabled, Disabled, White, 40, None);
        var boardWrapper:BoardWrapper = new BoardWrapper(board);
        boardWrapper.maxPercentHeight = 100;
        boardWrapper.percentWidth = 100;
        boardWrapper.horizontalAlign = 'center';
        boardWrapper.verticalAlign = 'center';
        boardContainer.addComponent(boardWrapper);
        Timer.delay(boardWrapper.validateNow, 500);

        var timer:Timer = new Timer(1000);
        timer.run = timerRun;
    }
}