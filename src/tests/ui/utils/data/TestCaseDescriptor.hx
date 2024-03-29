package tests.ui.utils.data;

import js.Cookie;
import tests.ui.utils.data.CheckModule.constructCheckModule;

class TestCaseDescriptor 
{
    public var checks:Map<String, CheckModule> = [];
    private var macros:Array<Macro> = [];

    private var untrackedMacros:Map<String, Macro> = [];

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

    public static function empty():TestCaseDescriptor
    {
        return new TestCaseDescriptor();
    }

    public function allMacros():Array<Macro>
    {
        return macros.copy();
    }

    public function getMacro(name:String):Macro
    {
        return Lambda.find(macros, m -> m.name == name);
    }

    public function removeMacro(m:Macro)
    {
        var requestedMacro = untrackedMacros.get(m.name);
        if (requestedMacro != null)
        {
            macros.remove(requestedMacro);
            untrackedMacros.remove(m.name);
            updateUntrackedMacrosCookie();
        }
        else 
            throw 'Attempting to remove published macro ${m.name}';
    }

    public function getUntrackedMacroNames():Array<String>
    {
        return [for (m in untrackedMacros) m.name];
    }

    public function getAllMacroNames():Array<String>
    {
        return macros.map(m -> m.name);
    }

    public function addMacro(m:Macro, ?updateCookie:Bool = true)
    {
        macros.push(m);
        untrackedMacros.set(m.name, m);

        if (updateCookie)
            updateUntrackedMacrosCookie();
    }

    public function renameMacro(m:Macro, newName:String)
    {
        if (!untrackedMacros.exists(m.name))
            throw 'Attempting to rename published macro ${m.name}';

        untrackedMacros.remove(m.name);
        untrackedMacros.set(newName, m);
        m.name = newName;
        updateUntrackedMacrosCookie();
    }

    private function updateUntrackedMacrosCookie()
    {
        var s:String = "";
        for (um in untrackedMacros)
            s += um.compactSerialize();
        Cookie.set("_" + UITest.getCurrentTestCase(), s, 60 * 60 * 24 * 2);
    }

    public function proposeMacros(exclude:Array<String>) 
    {
        for (m in untrackedMacros)
        {
            if (exclude.contains(m.name))
                continue;

            var message:String = 'A new macro was proposed:\n```\n' + m.serialize() + '\n```';
            Telegram.notifyAdmin(message);
        }
    }

    private function new() 
    {
        
    }
}