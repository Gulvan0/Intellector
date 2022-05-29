package tests.ui;

import haxe.Json;
import haxe.Resource;
import tests.ui.ArgumentType;
import js.Cookie;
import haxe.crypto.Md5;

enum CheckModule
{
    Normal(checklist:Array<String>);
    Stepwise(checks:Map<String, Array<String>>);
}

typedef EndpointArgument = {serializedValue:String, type:ArgumentType};

enum MacroStep 
{
    EndpointCall(endpointName:String, arguments:Array<EndpointArgument>);
    Event(serializedEvent:String);
}

typedef Macro = {name:String, sequence:Array<MacroStep>};

typedef TestCaseDescriptor = {checks:Map<String, CheckModule>, macros:Array<Macro>};

typedef TestCaseInfo = {descriptor:TestCaseDescriptor, passedChecksByModule:Map<String, Array<Int>>}

class DataKeeper 
{
    private static inline final cookieNamePrefix:String = 'ui:';

    private static var testCaseInfos:Map<String, TestCaseInfo> = [];

    //TODO: More methods

    private static function constructMacroEndpointArgument(json:Dynamic, testCaseName:String, macroName:String, endpointName:String):EndpointArgument
    {
        if (!Reflect.hasField(json, "value")) 
            throw 'Macro $macroName in test case $testCaseName has an \'endpointcall\' step which argument has no attribute \'value\' (endpoint: $endpointName)';
        if (!Reflect.hasField(json, "type")) 
            throw 'Macro $macroName in test case $testCaseName has an \'endpointcall\' step which argument has no attribute \'type\' (endpoint: $endpointName)';

        var argValue:String = cast(Reflect.field(json, "value"), String);
        var argTypeStr:String = cast(Reflect.field(json, "type"), String);
        var argType:ArgumentType = ArgumentType.createByName(argTypeStr);

        return {serializedValue: argValue, type: argType};
    }

    private static function constructEndpointCall(stepJson:Dynamic, testCaseName:String, macroName:String):MacroStep
    {
        if (!Reflect.hasField(stepJson, "endpoint")) 
            throw 'Macro $macroName in test case $testCaseName has an \'endpointcall\' step lacking attribute \'endpoint\'';
        if (!Reflect.hasField(stepJson, "args")) 
            throw 'Macro $macroName in test case $testCaseName has an \'endpointcall\' step lacking attribute \'args\'';

        var endpoint:String = cast(Reflect.field(stepJson, "endpoint"), String);
        var endpointArgs:Array<Dynamic> = cast(Reflect.field(stepJson, "args"), Array<Dynamic>);
        var endpointArgumentsEntry:Array<EndpointArgument> = [];

        for (arg in endpointArgs)
        {
            var constructedArgument:EndpointArgument = constructMacroEndpointArgument(arg, testCaseName, macroName, endpoint);
            endpointArgumentsEntry.push(constructedArgument);
        }

        return EndpointCall(endpoint, endpointArgumentsEntry);
    }

    private static function constructEventEntry(stepJson:Dynamic, testCaseName:String, macroName:String):MacroStep
    {
        if (!Reflect.hasField(stepJson, "eventstr")) 
            throw 'Macro $macroName in test case $testCaseName has an \'event\' step having no \'eventstr\' associated';

        var eventstr:String = cast(Reflect.field(stepJson, "eventstr"), String);

        return Event(eventstr);
    }

    private static function constructMacroStep(stepJson:Dynamic, testCaseName:String, macroName:String):MacroStep
    {
        if (!Reflect.hasField(stepJson, "type")) 
            throw 'Macro $macroName in test case $testCaseName has a step without a type';

        var macroType:String = cast(Reflect.field(stepJson, "type"), String);

        if (macroType == "endpointcall")
            return constructEndpointCall(stepJson, testCaseName, macroName);
        else if (macroType == "event")
            return constructEventEntry(stepJson, testCaseName, macroName);
        else
            throw 'Macro $macroName in test case $testCaseName has a step with invalid type \'$macroType\'';
    }

    private static function constructMacro(json:Dynamic, testCaseName:String):Macro
    {
        if (!Reflect.hasField(json, "name")) 
            throw 'Test case $testCaseName has a macro without a name';

        var macroName = Reflect.field(json, "name");

        if (!Reflect.hasField(json, "sequence")) 
            throw 'Macro $macroName in test case $testCaseName doesn\'t have attribute \'sequence\'';

        var macroSequence:Array<Dynamic> = cast(Reflect.field(json, "sequence"), Array<Dynamic>);

        var constructedMacroSequence:Array<MacroStep> = [];

        for (macroStep in macroSequence)
        {
            var constructedStep:MacroStep = constructMacroStep(macroStep, testCaseName, macroName);
            constructedMacroSequence.push(constructedStep);
        }
        
        return {name: macroName, sequence: constructedMacroSequence}; 
    }

    private static function constructCheckModuleMap(json:Dynamic, testCaseName:String):Map<String, CheckModule>
    {
        var map:Map<String, CheckModule> = [];

        for (checkModuleName in Reflect.fields(json))
        {
            var moduleObj = Reflect.field(json, checkModuleName);

            if (!Reflect.hasField(moduleObj, "steps")) 
                throw 'Module $checkModuleName in test case $testCaseName doesn\'t have attribute \'steps\'';
            if (!Reflect.hasField(moduleObj, "content")) 
                throw 'Module $checkModuleName in test case $testCaseName doesn\'t have attribute \'content\'';

            var steps:Bool = Reflect.field(moduleObj, "steps");
            var content = Reflect.field(moduleObj, "content");
            
            if (steps)
            {
                var module:CheckModule = constructStepwiseCheckModule(content, testCaseName, checkModuleName);
                map.set(checkModuleName, module);
            }
            else
            {
                var checklist:Array<String> = content;
                var module:CheckModule = Normal(checklist);
                map.set(checkModuleName, module);
            }
        }

        return map;
    }

    private static function constructStepwiseCheckModule(moduleJson:Dynamic, testCaseName:String, moduleName:String):CheckModule
    {
        var checkMap:Map<String, Array<String>> = [];

        for (step in Reflect.fields(moduleJson))
        {
            var checklist:Array<String> = Reflect.field(moduleJson, step);
            if ((Std.parseInt(step) == null || Std.parseInt(step) < 0) && step != "common")
                throw 'Invalid step \'$step\' in module $moduleName of test case $testCaseName';
            checkMap.set(step, checklist);
        }

        return Stepwise(checkMap);
    }

    //TODO: Clarify naming

    public static function load() 
    {
        var infosJSON:String = Resource.getString("test_case_infos");
        if (infosJSON == null)
            infosJSON = haxe.Http.requestUrl("https://raw.githubusercontent.com/Gulvan0/Intellector/main/Source/tests/ui/test_case_infos.json");
        
        var infosObj = Json.parse(infosJSON);

        //TODO: Move to own function
        for (className in Reflect.fields(infosObj))
        {
            var testCaseDescriptor:TestCaseDescriptor = {checks: [], macros: []};
            var testCasePassedChecks:Map<String, Array<Int>> = [];

            var infoObj = Reflect.field(infosObj, className);

            if (Reflect.hasField(infoObj, "checks"))
            {
                var checks = Reflect.field(infoObj, "checks");
                testCaseDescriptor.checks = constructCheckModuleMap(checks, className);
            }

            if (Reflect.hasField(infoObj, "macros"))
            {
                var macros:Array<Dynamic> = cast(Reflect.field(infoObj, "macros"), Array<Dynamic>);

                for (macroObj in macros)
                {
                    var constructedMacro:Macro = constructMacro(macroObj, className);
                    testCaseDescriptor.macros.push(constructedMacro);
                }
            }

            //TODO: construct passed checks based on cookies

            testCaseInfos.set(className, {descriptor: testCaseDescriptor, passedChecksByModule: testCasePassedChecks});
        }
    }

    public static function save() 
    {
        //TODO: Fill
    }
}