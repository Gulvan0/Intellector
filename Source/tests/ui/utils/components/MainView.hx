package tests.ui.utils.components;

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
    private var board:SelectableBoard;

    //TODO: Keep history in UITest
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
            var possibleValues:Array<Dynamic> = Reflect.field(component, FieldNaming.initParamValuesField(parameter));
            var selectedValue:Dynamic = possibleValues[selectedIndex];
            Reflect.setField(component, FieldNaming.initParamField(parameter), selectedValue);
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
        //TODO: Fill (create dialog)
        //DataKeeper.get(currentTestCase).descriptor.proposeMacros();
    }

    private function timerRun()
    {
        board.setSituation(component._provide_situation());
    }

    public function new(component:TestedComponent, initParams:Array<MaterializedInitParameter<Dynamic>>)
    {
        super();
        this.currentTestCase = Type.getClassName(Type.getClass(component));
        this.component = component;
        this.initParams = initParams;

        testedComponentBox.addComponent(component);

        componentNameLabel.htmlText = 'Component: <u>$currentTestCase</u>';

        for (param in initParams)
        {
            var paramEntry:InitParameterEntry = new InitParameterEntry(param.displayName, param.possibleValues.map(Std.string));
            initParamEntries.set(param.identifier, paramEntry);
            initParamsVBox.addComponent(paramEntry);
        }

        //TODO: Add & Bind Actions
        //TODO: Add & Bind Sequences

        //TODO: Add & Bind Checks

        board = new SelectableBoard(Situation.starting(), Disabled, Disabled);
        var boardWrapper:BoardWrapper = new BoardWrapper(board);
        boardWrapper.percentWidth = 100;
        boardContainer.addComponent(boardWrapper);

        var timer:Timer = new Timer(1000);
        timer.run = timerRun;
    }
}