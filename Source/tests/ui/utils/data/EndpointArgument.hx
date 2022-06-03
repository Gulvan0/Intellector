package tests.ui.utils.data;

import struct.Situation;
import struct.Ply;

class EndpointArgument
{
    public final value:Dynamic;
    public final type:ArgumentType;

    public static function construct(json:Dynamic, testCaseName:String, macroName:String, endpointName:String):EndpointArgument
    {
        if (!Reflect.hasField(json, "value")) 
            throw 'Macro $macroName in test case $testCaseName has an \'endpointcall\' step which argument has no attribute \'value\' (endpoint: $endpointName)';
        if (!Reflect.hasField(json, "type")) 
            throw 'Macro $macroName in test case $testCaseName has an \'endpointcall\' step which argument has no attribute \'type\' (endpoint: $endpointName)';

        var argValue:String = cast(Reflect.field(json, "value"), String);
        var argTypeStr:String = cast(Reflect.field(json, "type"), String);
        var argType:ArgumentType = ArgumentType.createByName(argTypeStr);

        return new EndpointArgument(argValue, argType);
    }

    public function asString():String
    {
        return switch type 
        {
            case AInt, AFloat, AString, AEnumerable: Std.string(value);
            case APly: cast(value, Ply).serialize();
        }
    }

    public function getDisplayText(currentSituation:Situation):String
    {
        return switch type 
        {
            case AInt, AFloat, AString, AEnumerable: Std.string(value);
            case APly: cast(value, Ply).toNotation(currentSituation);
        }
    }

    public function new(serializedValue:String, type:ArgumentType)
    {
        this.type = type;
        this.value = switch type 
        {
            case AInt: Std.parseInt(serializedValue);
            case AFloat: Std.parseFloat(serializedValue);
            case AString: serializedValue;
            case AEnumerable: serializedValue;
            case APly: Ply.deserialize(serializedValue);
        }
    }
}