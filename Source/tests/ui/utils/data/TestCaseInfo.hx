package tests.ui.utils.data;

import js.Cookie;
using utils.StringUtils;

class TestCaseInfo 
{
    public var descriptor:TestCaseDescriptor;
    public var passedChecksByModule:Map<String, Array<Int>>;

    private static function constructPassedChecks(testCaseName:String):Map<String, Array<Int>>
    {
        var testCasePassedChecks:Map<String, Array<Int>> = [];

        var cookieStr:Null<String> = Cookie.get(testCaseName);
        if (cookieStr == null)
            return testCasePassedChecks;

        var moduleName:String = "";
        var checkNum:Int = 0;
        for (char in cookieStr)
        {
            if (char == "0" || char == "1")
            {
                if (!testCasePassedChecks.exists(moduleName))
                    testCasePassedChecks.set(moduleName, []);

                if (char == "1")
                    testCasePassedChecks[moduleName].push(checkNum);

                checkNum++;
            }
            else 
            {
                if (checkNum > 0)
                {
                    moduleName = "";
                    checkNum = 0;
                }
                moduleName += char;
            }
        }
        
        return testCasePassedChecks;
    }

    public static function construct(json:Dynamic, testCaseName:String):TestCaseInfo
    {
        var descriptor:TestCaseDescriptor = TestCaseDescriptor.construct(json, testCaseName);
        var passedChecksMap:Map<String, Array<Int>> = constructPassedChecks(testCaseName);
    
        return new TestCaseInfo(descriptor, passedChecksMap);
    }

    private function new(descriptor:TestCaseDescriptor, passedChecksByModule:Map<String, Array<Int>>) 
    {
        
    }
}