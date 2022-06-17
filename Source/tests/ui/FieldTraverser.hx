package tests.ui;

import tests.ui.utils.data.EndpointArgument;
import tests.ui.utils.data.ActionEndpointPrompt;
import utils.StringUtils;
import haxe.rtti.Meta;
import tests.ui.utils.FieldNaming;
import tests.ui.utils.data.MaterializedInitParameter;
import tests.ui.utils.data.MaterializedEndpoint;
import ds.ListSet;
using StringTools;

typedef FieldTraverserResults = {endpoints:Array<MaterializedEndpoint>, initParameters:Array<MaterializedInitParameter<Dynamic>>};

class FieldTraverser 
{
    private var testCase:String;
    private var component:TestedComponent;

    private var endpoints:Array<MaterializedEndpoint>;
    private var initParameters:Array<MaterializedInitParameter<Dynamic>>;

    private function constructActionEndpoint(fieldName:String, displayName:String):MaterializedEndpoint
    {
        var splitterValues:Null<Array<String>> = getMetaValue(fieldName, "split", true);
        var prompts:Array<ActionEndpointPrompt> = [];

        var promptMeta:Null<Array<Dynamic>> = getMetaValue(fieldName, "prompt", true);

        if (promptMeta != null)
        {
            var type:Null<ArgumentType> = null;
            var displayName:Null<String> = null;

            for (tagArgument in promptMeta)
            {
                if (type == null)
                    type = ArgumentType.createByName(cast(tagArgument, String));
                else if (displayName == null)
                    displayName = cast(tagArgument, String);
                else if (Std.isOfType(tagArgument, String))
                {
                    prompts.push(new ActionEndpointPrompt(displayName, type));
                    type = ArgumentType.createByName(cast(tagArgument, String));
                    displayName = null;
                }
                else if (Std.isOfType(tagArgument, Array))
                {
                    var defaultValues:Array<EndpointArgument> = [];
                    for (defaultArg in cast(tagArgument, Array<Dynamic>))
                        defaultValues.push(new EndpointArgument(defaultArg, type));

                    prompts.push(new ActionEndpointPrompt(displayName, type, defaultValues));
                    type = null;
                    displayName = null;
                }
                else
                    throw 'Unexpected @prompt parameter type. Test case: $testCase. Endpoint: $fieldName. Parameter: $tagArgument';
            }

            if (type != null)
                if (displayName != null)
                    prompts.push(new ActionEndpointPrompt(displayName, type));
                else
                    throw 'Unterminated @prompt parameter. Test case: $testCase. Endpoint: $fieldName. Parameter type: $type';
        }

        return Action(fieldName, displayName, splitterValues, prompts);
    }

    private function constructSequenceEndpoint(fieldName:String, displayName:String):MaterializedEndpoint
    {
        return Sequence(fieldName, displayName, getMetaValue(fieldName, "iterations"));
    }

    private function constructInitParameter(fieldName:String, displayName:String, fieldOwnName:String):MaterializedInitParameter<Dynamic>
    {
        var field = Reflect.field(component, fieldName);
        var possibleValues:Array<Dynamic> = Reflect.field(component, FieldNaming.initParamValuesField(fieldOwnName));
        var labels = Reflect.field(component, FieldNaming.initParamLabelsField(fieldOwnName));

        if (field == null)
            throw 'Init parameter $fieldOwnName of test case $testCase does not have a default value';

        if (possibleValues == null)
        {
            if (Std.isOfType(field, Bool))
                possibleValues = [true, false];
            else if (Reflect.isEnumValue(field))
                possibleValues = Type.getEnum(field).createAll();
            else
                throw 'Init parameter $fieldOwnName of test case $testCase does not have a list of possible values (this is allowed only for Bool and EnumValue)';
        }

        if (labels == null)
            labels = possibleValues.map(Std.string);

        return new MaterializedInitParameter(fieldName, StringUtils.asFrankenstein(fieldOwnName), displayName, possibleValues, labels);
    }

    private function getMetaValue(fieldName:String, metatagName:String, ?optional:Bool = false):Dynamic
    {
        var testCaseClass = Type.getClass(component);
        var classMetas = Meta.getFields(testCaseClass);
        var methodMetas = Reflect.field(classMetas, fieldName);

        if (methodMetas == null || Reflect.field(methodMetas, metatagName) == null)
            if (optional)
                return null;
            else
                throw 'Metatag $metatagName not found for field $fieldName of test case ${UITest.getCurrentTestCase()}';
        
        return Reflect.field(methodMetas, metatagName);
    }

    private function processField(fieldName:String)
    {
        if (Reflect.field(component, fieldName) == null)
            throw 'Field not found: $fieldName';

        var fieldPrefix:String = FieldNaming.getFieldPrefix(fieldName);
        var fieldOwnName:String = fieldName.replace(fieldPrefix, "");

        var displayName:String = StringUtils.asPhrase(fieldOwnName);
        var fieldType:FieldType = FieldNaming.fieldTypeByPrefix(fieldPrefix);

        switch fieldType
        {
            case null:
                throw 'Unknown field type. Field: $fieldName';
            case ActionEndpoint:
                endpoints.push(constructActionEndpoint(fieldName, displayName));
            case SequenceEndpoint:
                endpoints.push(constructSequenceEndpoint(fieldName, displayName));
            case InitParameter:
                initParameters.push(constructInitParameter(fieldName, displayName, fieldOwnName));
            case Provision, InitParameterValues, InitParameterLabels:
                return;
        }
    }

    private function getRelevantFields():ListSet<String> 
    {
        var allFields:Array<String> = Type.getInstanceFields(Type.getClass(component));
        var superClassFields:ListSet<String> = new ListSet(Type.getInstanceFields(Type.getSuperClass(TestedComponent)));
        var relevantFields:ListSet<String> = new ListSet(allFields.length);
        for (fieldName in allFields)
            if (fieldName.startsWith("_") && !superClassFields.has(fieldName))
                relevantFields.set(fieldName);
        return relevantFields;
    }

    public function traverse():FieldTraverserResults
    {
        endpoints = [];
        initParameters = [];
        
        for (field in getRelevantFields())
            processField(field);

        return {endpoints: endpoints, initParameters: initParameters};
    }

    public function new(component:TestedComponent)
    {
        this.testCase = UITest.getCurrentTestCase();
        this.component = component;
    }
}