package tests.ui;

import haxe.Http;
import tests.ui.utils.data.TestCaseInfo;
import haxe.Json;
import haxe.Resource;

class DataKeeper 
{
    private static var testCaseInfos:Map<String, TestCaseInfo>;

    private static function constructTestCaseMap(json:Dynamic):Map<String, TestCaseInfo>
    {
        var map:Map<String, TestCaseInfo> = [];

        for (className in Reflect.fields(json))
        {
            var testCaseJson = Reflect.field(json, className);
            var info:TestCaseInfo = TestCaseInfo.construct(testCaseJson, className);

            map.set(className, info);
        }

        return map;
    }

    public static function getUntrackedMacroNames():Array<String>
    {
        return getCurrent().descriptor.getUntrackedMacroNames();
    }

    public static function getAllMacroNames():Array<String>
    {
        return getCurrent().descriptor.getAllMacroNames();
    }

    public static function proposeMacros(excludedMacroNames:Array<String>) 
    {
        getCurrent().descriptor.proposeMacros(excludedMacroNames);
    }

    public static function get(testCase:String):TestCaseInfo
    {
        var info:Null<TestCaseInfo> = testCaseInfos.get(testCase);
        if (info == null)
        {
            trace('Data for test case $testCase was not loaded. Loaded cases: ${[for (s in testCaseInfos.keys()) s].join(', ')}');
            testCaseInfos.set(testCase, TestCaseInfo.empty(testCase));
            return testCaseInfos.get(testCase);
        }
        else
            return info;
    }

    public static function getCurrent():TestCaseInfo
    {
        return get(UITest.getCurrentTestCase());
    }

    public static function load(onLoaded:Void->Void) 
    {
        function onRawTestCaseInfosRetrieved(rawDataStr:String) 
        {
            testCaseInfos = constructTestCaseMap(Json.parse(rawDataStr));
            onLoaded();
        }

        var rawDataStr:String = Resource.getString("test_case_infos");
        if (rawDataStr == null)
        {
            var request:Http = new Http("https://raw.githubusercontent.com/Gulvan0/Intellector/main/Source/tests/ui/test_case_infos.json");
            request.onData = onRawTestCaseInfosRetrieved;
            request.request();
        }
        else
            onRawTestCaseInfosRetrieved(rawDataStr);
    }
}