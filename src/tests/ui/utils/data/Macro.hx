package tests.ui.utils.data;

import haxe.Json;
import tests.ui.utils.data.MacroStep.constructMacroStep;
import net.shared.board.RawPly;

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

    public function compactSerialize():String
    {
        var s:String = "";
        s += name;
        s += "[";

        var steps:Array<String> = [];
        for (step in sequence)
        {
            var stepStr:String = "";
            switch step 
            {
                case EndpointCall(endpointName, arguments):
                    stepStr += 'c';
                    stepStr += endpointName;
                    for (arg in arguments)
                    {
                        stepStr += '|';
                        switch arg.type 
                        {
                            case AInt:
                                stepStr += 'i' + cast(arg.value, Int);
                            case AFloat:
                                stepStr += 'f' + cast(arg.value, Float);
                            case AString:
                                stepStr += 's' + cast(arg.value, String);
                            case AEnumerable:
                                stepStr += 'e' + cast(arg.value, String);
                            case APly:
                                stepStr += 'p' + cast(arg.value, RawPly).serialize();
                        }
                    }
                case Event(serializedEvent):
                    stepStr += 'e';
                    stepStr += serializedEvent;
                case Initialization(paramValueIndexes):
                    stepStr += 'i';
                    var paramEntries:Array<String> = [];
                    for (key => value in paramValueIndexes)
                        paramEntries.push(key + ":" + value);
                    stepStr += paramEntries.join("|");
            }
            steps.push(stepStr);
        }

        s += steps.join(";"); 
        s += "]";

        return s;
    }

    public static function compactDeserialize(macroName:String, bracketContent:String):Macro
    {
        var stepStrs:Array<String> = bracketContent.split(';');
        var sequence:Array<MacroStep> = [];
        for (stepStr in stepStrs)
        {
            if (stepStr.charAt(0) == 'c')
            {
                var args:Array<String> = stepStr.substr(1).split("|");
                var endpointName:String = args.shift();

                var endpointArgumentsEntry:Array<EndpointArgument> = [];

                for (arg in args)
                {
                    var typeLetter:String = arg.charAt(0);
                    var argType:ArgumentType = switch typeLetter
                    {
                        case 'i': AInt;
                        case 'f': AFloat;
                        case 's': AString;
                        case 'e': AEnumerable;
                        case 'p': APly;
                        default: throw 'Letter does not correspond to any of the possible argument types: $typeLetter';
                    }
                    var constructedArgument:EndpointArgument = EndpointArgument.fromSerialized(arg.substr(1), argType);
                    endpointArgumentsEntry.push(constructedArgument);
                }

                sequence.push(EndpointCall(endpointName, endpointArgumentsEntry));
            }
            else if (stepStr.charAt(0) == 'e')
                sequence.push(Event(stepStr.substr(1)));
            else if (stepStr.charAt(0) == 'i')
            {
                var paramValueIndexes:Map<String, Int> = [];
                var pairs:Array<String> = stepStr.substr(1).split("|");
                for (pair in pairs)
                {
                    var kv:Array<String> = pair.split(":");
                    paramValueIndexes.set(kv[0], Std.parseInt(kv[1]));
                }
                sequence.push(Initialization(paramValueIndexes));
            }
        }

        return new Macro(macroName, sequence);
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
                            case APly: cast(arg.value, RawPly).serialize();
                            default: arg.value;
                        }
                        argsJson.push(value);
                    }
                    sequenceJson.push({type: 'endpointcall', endpoint: endpointName, args: argsJson});
                case Event(serializedEvent):
                    sequenceJson.push({type: 'event', eventstr: serializedEvent});
                case Initialization(paramValueIndexes):
                    var paramMapJson:Dynamic = {};
                    for (key => value in paramValueIndexes.keyValueIterator())
                        Reflect.setField(paramMapJson, key, value);
                    sequenceJson.push({type: 'init', params: paramMapJson});
            }
        }

        var json:Dynamic = {name: name, sequence: sequenceJson};

        return Json.stringify(json, null, "    ");
    }

    public function new(name:String, sequence:Array<MacroStep>) 
    {
        this.name = name;
        this.sequence = sequence;
    }
}