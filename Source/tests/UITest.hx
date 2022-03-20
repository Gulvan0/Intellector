package tests;

import js.Browser;
import haxe.ui.components.Label;
import haxe.rtti.Meta;
import haxe.Timer;
import haxe.ui.components.CheckBox;
import haxe.ui.components.Button;
import haxe.ui.containers.VBox;
import haxe.ui.containers.VerticalButtonBar;
import openfl.display.Sprite;
import haxe.ui.containers.Box;
import haxe.ui.containers.ScrollView;
import gfx.components.SpriteWrapper;
import haxe.ui.containers.HBox;
using StringTools;

enum EndpointType
{
    Action;
    Auto;
    Sequence;
}

class UITest extends HBox
{
    private var component:Sprite;

    private var actionBar:VerticalButtonBar;
    private var checksVBox:VBox;

    private var exploredFieldNamesSet:Map<String, Bool> = [];
    private var checkFieldNamesSet:Map<String, Bool> = [];

    private var seqIterators:Map<String, Int> = [];
    private var seqIteratorLimits:Map<String, Int> = [];
    private var seqButtons:Map<String, Button> = [];

    private function getFieldNamePrefix(type:EndpointType):String
    {
        return switch type
        {
            case Action: "_act_";
            case Auto: "_auto_";
            case Sequence: "_seq_";
        }
    }

    private function getRequiredMetatags(type:EndpointType):Array<String>
    {
        return switch type
        {
            case Action: [];
            case Auto: ["interval", "iterations"];
            case Sequence: ["steps"];
        }
    }

    private function getSequenceButtonText(pureName:String) 
    {
        return pureName + ' / Step ' + seqIterators[pureName];
    }

    private function actionCallback(field:Void->Void, e)
    {
        Reflect.callMethod(component, field, []);
    }

    private function autoCallback(field:Void->Void, interval:Int, iterations:Int, e)
    {
        actionBar.disabled = true;
        var timer:Timer = new Timer(interval);
        var i:Int = 0;
        timer.run = () -> {
            Reflect.callMethod(component, field, [i]);
            i++;
            if (i == iterations)
            {
                timer.stop();
                actionBar.disabled = false;
            }
        };
    }

    private function sequenceCallback(field:Void->Void, pureName:String, e)
    {
        Reflect.callMethod(component, field, [seqIterators[pureName]]);
        seqIterators[pureName]++;
        seqIterators[pureName] %= seqIteratorLimits[pureName];
        seqButtons[pureName].text = getSequenceButtonText(pureName);
    }

    private function autoCheckBoxes(checkName:String):Array<CheckBox>
    {
        var checkboxes:Array<CheckBox> = [];

        var checks:Array<String> = Reflect.field(component, checkName);
        for (check in checks)
        {
            var checkBox:CheckBox = new CheckBox();
            checkBox.text = check;
            checkBox.percentWidth = 100;
            checkboxes.push(checkBox);
        }

        return checkboxes;
    }

    private function sequenceCheckBoxes(checkName:String):Array<CheckBox>
    {
        var checkboxes:Array<CheckBox> = [];

        var checkMap:Map<Int, Array<String>> = Reflect.field(component, checkName);
        for (step => stepChecks in checkMap.keyValueIterator())
            for (check in stepChecks)
            {
                var checkBox:CheckBox = new CheckBox();
                checkBox.percentWidth = 100;
                if (step == -1)
                    checkBox.text = check;
                else
                    checkBox.text = 'Step $step: $check';
                checkboxes.push(checkBox);
            }

        return checkboxes;
    }

    private function retrieveMetaValues(fieldName:String, tagNames:Array<String>):Map<String, Dynamic>
    {
        var values:Map<String, Dynamic> = [];

        var classMetas = Meta.getFields(Type.getClass(component));
        var methodMetas = Reflect.field(classMetas, fieldName);
        if (methodMetas == null)
            throw 'No metatags: $fieldName';

        for (tagName in tagNames)
        {
            var tagValue = Reflect.field(methodMetas, tagName);
            if (tagValue == null)
                throw 'No @$tagName metatag: $fieldName';
            else
                values.set(tagName, tagValue);
        }

        return values;
    }

    private function processFields(type:EndpointType, fieldNames:Array<String>) 
    {
        var requiredMetatags:Array<String> = getRequiredMetatags(type);
        var namePrefix:String = getFieldNamePrefix(type);

        for (fieldName in fieldNames)
        {
            var pureName:String = fieldName.replace(namePrefix, '');
            if (exploredFieldNamesSet.exists(pureName))
                throw 'Duplicate field: $pureName';

            var field = Reflect.field(component, fieldName);
            if (!Reflect.isFunction(field))
                throw 'Not a function field: $fieldName';

            var metavalues:Map<String, Dynamic> = type == Action? [] : retrieveMetaValues(fieldName, requiredMetatags);

            var btn = new Button();
            btn.percentWidth = 100;
            actionBar.addComponent(btn);

            switch type
            {
                case Action: 
                    btn.onClick = actionCallback.bind(field);
                    btn.text = pureName;
                case Auto: 
                    btn.onClick = autoCallback.bind(field, metavalues["interval"], metavalues["iterations"]);
                    btn.text = '$pureName / auto';
                case Sequence: 
                    seqIterators.set(pureName, 0);
                    seqIteratorLimits.set(pureName, metavalues["steps"]);
                    seqButtons.set(pureName, btn);
                    btn.onClick = sequenceCallback.bind(field, pureName);
                    btn.text = getSequenceButtonText(pureName);
            }

            var checkName:String = '_checks_' + pureName;
            if (checkFieldNamesSet.exists(checkName))
            {
                var header:Label = new Label();
                header.text = pureName;
                header.percentWidth = 100;
                header.customStyle.fontBold = true;
                checksVBox.addComponent(header);
    
                var checkboxes:Array<CheckBox> = switch type
                {
                    case Action: [];
                    case Auto: autoCheckBoxes(checkName);
                    case Sequence: sequenceCheckBoxes(checkName);
                }

                for (checkbox in checkboxes)
                    checksVBox.addComponent(checkbox);
            }

            exploredFieldNamesSet.set(pureName, true);
        }
    }

    public function new(component:Sprite, ?contentWidthPercent:Float = 72) 
    {
        super();
        this.component = component;
        this.width = Browser.window.innerWidth;
        this.height = Browser.window.innerHeight;
        this.customStyle.padding = 5;

        var componentWrapper:SpriteWrapper = new SpriteWrapper();
        componentWrapper.sprite = component;
        componentWrapper.horizontalAlign = 'center';
        componentWrapper.verticalAlign = 'center';

        var componentBox:Box = new Box();
        componentBox.percentWidth = contentWidthPercent;
        componentBox.percentHeight = 100;
        componentBox.addComponent(componentWrapper);

        actionBar = new VerticalButtonBar();
        actionBar.toggle = false;
        actionBar.percentWidth = 100;

        var actionsSV:ScrollView = new ScrollView();
        actionsSV.percentWidth = (100 - contentWidthPercent) / 2;
        actionsSV.percentHeight = 100;
        actionsSV.percentContentWidth = 100;
        actionsSV.addComponent(actionBar);

        checksVBox = new VBox();
        checksVBox.percentWidth = 100;

        var checksSV:ScrollView = new ScrollView();
        checksSV.percentWidth = (100 - contentWidthPercent) / 2;
        checksSV.percentHeight = 100;
        checksSV.percentContentWidth = 100;
        checksSV.addComponent(checksVBox);

        addComponent(componentBox);
        addComponent(actionsSV);
        addComponent(checksSV);

        var endpointFieldNames:Map<EndpointType, Array<String>> = [for (type in EndpointType.createAll()) type => []];

        var allFields = Type.getInstanceFields(Type.getClass(component));
        var commonFields = Type.getInstanceFields(Sprite);
        
        var sMap:Map<String, Bool> = [];
        for (cf in commonFields)
            sMap.set(cf, true);
        
        for (fieldName in allFields) 
            if (fieldName.startsWith('_') && !sMap.exists(fieldName))
                if (fieldName.startsWith('_checks_'))
                    checkFieldNamesSet.set(fieldName, true);
                else
                    for (type in EndpointType.createAll())
                        if (fieldName.startsWith(getFieldNamePrefix(type)))
                            endpointFieldNames[type].push(fieldName);

        for (endpointType in [Action, Auto, Sequence])
            processFields(endpointType, endpointFieldNames[endpointType]);
    }
}