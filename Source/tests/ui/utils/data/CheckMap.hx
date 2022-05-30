package tests.ui.utils.data;

class CheckMap
{
    public var commonChecks:CheckList;
    public var stepChecks:Map<Int, CheckList>;

    private var checkedStepsOrdered:Array<Int> = [];

    public static function construct(moduleJson:Dynamic, testCaseName:String, moduleName:String):CheckMap
    {
        var checkMap:CheckMap = new CheckMap();

        for (step in Reflect.fields(moduleJson))
        {
            var checklist:Array<String> = Reflect.field(moduleJson, step);

            var intStep = Std.parseInt(step);

            if (step == "common")
                checkMap.commonChecks = checklist;
            else if (intStep == null || intStep < 0)
                throw 'Invalid step \'$step\' in module $moduleName of test case $testCaseName';
            else
            {
                checkMap.stepChecks.set(intStep, checklist);
                checkMap.checkedStepsOrdered.push(intStep);
            }
        }

        checkMap.checkedStepsOrdered.sort((x, y)->x-y);
        return checkMap;
    }

    public function getCheckIndex(checkText:String):Int
    {   
        var checksBefore:Int = 0;

        var indexInList:Int = commonChecks.indexOf(checkText);
        if (indexInList != -1)
            return indexInList;

        checksBefore += commonChecks.length;

        for (step in checkedStepsOrdered)
        {
            var checklist = stepChecks.get(step);
            var indexInList:Int = checklist.indexOf(checkText);
            if (indexInList != -1)
                return checksBefore + indexInList;

            checksBefore += checklist.length;
        }

        return -1;
    }

    private function new() 
    {
        
    }
}