package tests.ui.utils.data;

import haxe.Json;
import struct.Ply;
import tests.ui.utils.data.MacroStep.constructMacroStep;

class Macro
{
    public var name:String;
    private final sequence:Array<MacroStep>;
    
    public static function construct(json:Dynamic, testCaseName:String):Macro
    {
        if (!Reflect.hasField(json, "name")) 
            throw 'Test case $testCaseName has a macro without a name';

        var macroName = Reflect.field(json, "name");

        if (!Reflect.hasField(json, "sequence")) 
            throw 'Macro $macroName in test case $testCaseName doesn\'t have attribute \'sequence\'';

        var macroSequence:Array<Dynamic> = cast(Reflect.field(json, "sequence"), Array<Dynamic>);

        var constructedMacroSequence:Array<MacroStep> = [];

        for (macroStep in macroSequence)
        {
            var constructedStep:MacroStep = constructMacroStep(macroStep, testCaseName, macroName);
            constructedMacroSequence.push(constructedStep);
        }
        
        return new Macro(macroName, constructedMacroSequence);
    }

    public function getStep(step:Int):MacroStep
    {
        return sequence[step];
    }

    public function totalSteps():Int
    {
        return sequence.length;
    }

    public function iterator()
    {
        return sequence.iterator();
    }

    public function serialize():String
    {
        var sequenceJson:Array<Dynamic> = [];
        for (step in sequence)
        {
            switch step 
            {
                case EndpointCall(endpointName, arguments):
                    var argsJson:Array<Dynamic> = [];
                    for (arg in arguments)
                    {
                        var value:Dynamic = switch arg.type 
                        {
                            case APly: cast(arg.value, Ply).serialize();
                            default: arg.value;
                        }
                        argsJson.push(value);
                    }
                    sequenceJson.push({type: 'endpointcall', endpoint: endpointName, args: argsJson});
                case Event(serializedEvent):
                    sequenceJson.push({type: 'event', eventstr: serializedEvent});
            }
        }

        var json:Dynamic = {name: name, sequence: sequenceJson};

        return Json.stringify(json, null, "\t");
    }

    public function new(name:String, sequence:Array<MacroStep>) 
    {
        this.name = name;
        this.sequence = sequence;
    }
}