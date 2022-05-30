package tests.ui.utils.data;

import tests.ui.utils.data.EndpointArgument;

enum MacroStep 
{
    EndpointCall(endpointName:String, arguments:Array<EndpointArgument>);
    Event(serializedEvent:String);
}

private function constructEndpointCall(stepJson:Dynamic, testCaseName:String, macroName:String):MacroStep
{
    if (!Reflect.hasField(stepJson, "endpoint")) 
        throw 'Macro $macroName in test case $testCaseName has an \'endpointcall\' step lacking attribute \'endpoint\'';
    if (!Reflect.hasField(stepJson, "args")) 
        throw 'Macro $macroName in test case $testCaseName has an \'endpointcall\' step lacking attribute \'args\'';

    var endpoint:String = cast(Reflect.field(stepJson, "endpoint"), String);
    var endpointArgs:Array<Dynamic> = cast(Reflect.field(stepJson, "args"), Array<Dynamic>);
    var endpointArgumentsEntry:Array<EndpointArgument> = [];

    for (arg in endpointArgs)
    {
        var constructedArgument:EndpointArgument = EndpointArgument.construct(arg, testCaseName, macroName, endpoint);
        endpointArgumentsEntry.push(constructedArgument);
    }

    return EndpointCall(endpoint, endpointArgumentsEntry);
}

private function constructEventEntry(stepJson:Dynamic, testCaseName:String, macroName:String):MacroStep
{
    if (!Reflect.hasField(stepJson, "eventstr")) 
        throw 'Macro $macroName in test case $testCaseName has an \'event\' step having no \'eventstr\' associated';

    var eventstr:String = cast(Reflect.field(stepJson, "eventstr"), String);
    return Event(eventstr);
}

function constructMacroStep(stepJson:Dynamic, testCaseName:String, macroName:String):MacroStep
{
    if (!Reflect.hasField(stepJson, "type")) 
        throw 'Macro $macroName in test case $testCaseName has a step without a type';

    var macroType:String = cast(Reflect.field(stepJson, "type"), String);

    if (macroType == "endpointcall")
        return constructEndpointCall(stepJson, testCaseName, macroName);
    else if (macroType == "event")
        return constructEventEntry(stepJson, testCaseName, macroName);
    else
        throw 'Macro $macroName in test case $testCaseName has a step with invalid type \'$macroType\'';
}