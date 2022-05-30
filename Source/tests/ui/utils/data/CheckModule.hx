package tests.ui.utils.data;

import tests.ui.utils.data.CheckMap;
import tests.ui.utils.data.CheckList;
import tests.ui.utils.data.CheckList.construct as constructChecklist;

enum CheckModule
{
    Normal(checklist:CheckList);
    Stepwise(checks:CheckMap);
}

function constructCheckModule(moduleJson:Dynamic, testCaseName:String, moduleName:String):CheckModule
{
    if (!Reflect.hasField(moduleJson, "steps")) 
        throw 'Module $moduleName in test case $testCaseName doesn\'t have attribute \'steps\'';
    if (!Reflect.hasField(moduleJson, "content")) 
        throw 'Module $moduleName in test case $testCaseName doesn\'t have attribute \'content\'';

    var steps:Bool = Reflect.field(moduleJson, "steps");
    var content = Reflect.field(moduleJson, "content");
    
    if (steps)
        return Stepwise(CheckMap.construct(content, testCaseName, moduleName));
    else
        return Normal(constructChecklist(content, testCaseName, moduleName));
}

function getCheckIndex(module:CheckModule, checkText:String)
{
    switch module 
    {
        case Normal(checklist):
            return checklist.indexOf(checkText);
        case Stepwise(checks):
            return checks.getCheckIndex(checkText);
    }
}