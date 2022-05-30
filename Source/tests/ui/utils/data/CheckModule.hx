package tests.ui.utils.data;

enum CheckModule
{
    Normal(checklist:Array<String>);
    Stepwise(checks:Map<String, Array<String>>);
}

private function constructNormalCheckModule(moduleJson:Dynamic, testCaseName:String, moduleName:String):CheckModule
{
    var checklist:Array<String> = moduleJson;
    return Normal(checklist);
}

private function constructStepwiseCheckModule(moduleJson:Dynamic, testCaseName:String, moduleName:String):CheckModule
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

function constructCheckModule(moduleJson:Dynamic, testCaseName:String, moduleName:String):CheckModule
{
    if (!Reflect.hasField(moduleJson, "steps")) 
        throw 'Module $moduleName in test case $testCaseName doesn\'t have attribute \'steps\'';
    if (!Reflect.hasField(moduleJson, "content")) 
        throw 'Module $moduleName in test case $testCaseName doesn\'t have attribute \'content\'';

    var steps:Bool = Reflect.field(moduleJson, "steps");
    var content = Reflect.field(moduleJson, "content");
    
    if (steps)
        return constructStepwiseCheckModule(content, testCaseName, moduleName);
    else
        return constructNormalCheckModule(content, testCaseName, moduleName);
}