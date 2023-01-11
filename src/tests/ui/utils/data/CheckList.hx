package tests.ui.utils.data;

typedef CheckList = Array<String>;

function construct(moduleJson:Dynamic, testCaseName:String, moduleName:String):CheckList
{
    var checklist:Array<String> = moduleJson;
    return checklist;
}