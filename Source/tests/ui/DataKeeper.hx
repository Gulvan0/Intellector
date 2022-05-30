package tests.ui;

import haxe.Http;
import tests.ui.utils.data.TestCaseInfo;
import haxe.Json;
import haxe.Resource;
import tests.ui.ArgumentType;
import js.Cookie;
import haxe.crypto.Md5;

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

    public static function get(testCase:String):TestCaseInfo
    {
        return testCaseInfos.get(testCase);
    }

    public static function load() 
    {
        var rawDataStr:String = Resource.getString("test_case_infos");
        if (rawDataStr == null)
            rawDataStr = Http.requestUrl("https://raw.githubusercontent.com/Gulvan0/Intellector/main/Source/tests/ui/test_case_infos.json");
        
        testCaseInfos = constructTestCaseMap(Json.parse(rawDataStr));
    }
}