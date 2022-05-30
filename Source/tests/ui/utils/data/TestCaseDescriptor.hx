package tests.ui.utils.data;

import tests.ui.utils.data.CheckModule.constructCheckModule;

class TestCaseDescriptor 
{
    public var checks:Map<String, CheckModule> = [];
    public var macros:Array<Macro> = [];

    private static function constructCheckModuleMap(json:Dynamic, testCaseName:String):Map<String, CheckModule>
    {
        var map:Map<String, CheckModule> = [];
    
        for (checkModuleName in Reflect.fields(json))
        {
            var moduleJson = Reflect.field(json, checkModuleName);
            var module:CheckModule = constructCheckModule(moduleJson, testCaseName, checkModuleName);
            map.set(checkModuleName, module);
        }
    
        return map;
    }

    public static function construct(json:Dynamic, testCaseName:String):TestCaseDescriptor
    {
        var testCaseDescriptor:TestCaseDescriptor = new TestCaseDescriptor();

        if (Reflect.hasField(json, "checks"))
        {
            var checks = Reflect.field(json, "checks");
            testCaseDescriptor.checks = constructCheckModuleMap(checks, testCaseName);
        }

        if (Reflect.hasField(json, "macros"))
        {
            var macros:Array<Dynamic> = cast(Reflect.field(json, "macros"), Array<Dynamic>);

            for (macroObj in macros)
            {
                var constructedMacro:Macro = Macro.construct(macroObj, testCaseName);
                testCaseDescriptor.macros.push(constructedMacro);
            }
        }

        return testCaseDescriptor;
    }

    private function new() 
    {
        
    }
}