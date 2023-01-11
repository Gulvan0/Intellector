package tests.ui.utils.data;

import tests.ui.utils.data.CheckModule.getCheckIndex;
import js.Cookie;
using utils.StringUtils;

class TestCaseInfo 
{
    private var testCase:String;
    public var descriptor:TestCaseDescriptor;
    private var passedChecksByModule:Map<String, Array<Int>>;

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
    
        return new TestCaseInfo(testCaseName, descriptor, passedChecksMap);
    }

    public static function empty(testCaseName:String):TestCaseInfo
    {
        return new TestCaseInfo(testCaseName, TestCaseDescriptor.empty(), []);
    }

    public function savePassedChecks()
    {
        var cookieStr:String = "";

        for (moduleName => checkNums in passedChecksByModule.keyValueIterator())
        {
            var checksPart:String = "";

            var checkPassed:Array<Bool> = [];
            for (checkNum in checkNums)
                checkPassed[checkNum] = true;
            
            for (flag in checkPassed)
                if (flag == true)
                    checksPart += "1";
                else 
                    checksPart += "0";

            if (checksPart != "")
                cookieStr += moduleName + checksPart;
        }
        
        Cookie.set(testCase, cookieStr);
    }

    public function setCheck(moduleName:String, checkText:String, passed:Bool) 
    {
        var module:CheckModule = descriptor.checks.get(moduleName);

        var index:Int = getCheckIndex(module, checkText);
        if (index == -1)
            throw 'Check "$checkText" not found in module $moduleName of test case $testCase';

        if (passed)
        {
            if (!passedChecksByModule[moduleName].contains(index))
                passedChecksByModule[moduleName].push(index);
        }
        else
            passedChecksByModule[moduleName].remove(index);

        savePassedChecks();
    }

    public function getCheck(moduleName:String, checkText:String):Bool 
    {
        var module:CheckModule = descriptor.checks.get(moduleName);

        var index:Int = getCheckIndex(module, checkText);
        if (index == -1)
            throw 'Check "$checkText" not found in module $moduleName of test case $testCase';

        return passedChecksByModule[moduleName].contains(index);
    }

    private function new(testCase:String, descriptor:TestCaseDescriptor, passedChecksByModule:Map<String, Array<Int>>) 
    {
        this.testCase = testCase;
        this.descriptor = descriptor;
        this.passedChecksByModule = passedChecksByModule;
        for (moduleName in descriptor.checks.keys())
            if (!passedChecksByModule.exists(moduleName))
                passedChecksByModule.set(moduleName, []);
    }
}