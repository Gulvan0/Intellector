package tests.ui.utils.data;

import net.shared.board.Situation;
import net.shared.board.RawPly;

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

        var argValue = Std.string(Reflect.field(json, "value"));
        var argTypeStr:String = cast(Reflect.field(json, "type"), String);
        var argType:ArgumentType = ArgumentType.createByName(argTypeStr);

        return EndpointArgument.fromSerialized(argValue, argType);
    }

    public function asString():String
    {
        return switch type 
        {
            case AInt, AFloat, AString, AEnumerable: Std.string(value);
            case APly: cast(value, RawPly).serialize();
        }
    }

    public function getDisplayText(currentSituation:Situation):String
    {
        return switch type 
        {
            case AInt, AFloat, AString, AEnumerable: Std.string(value);
            case APly: cast(value, RawPly).toNotation(currentSituation);
        }
    }

    public static function fromSerialized(serializedValue:String, type:ArgumentType):EndpointArgument
    {
        var value:Dynamic = switch type 
        {
            case AInt: Std.parseInt(serializedValue);
            case AFloat: Std.parseFloat(serializedValue);
            case AString: serializedValue;
            case AEnumerable: serializedValue;
            case APly: RawPly.deserialize(serializedValue);
        }
        return new EndpointArgument(type, value);
    }

    public function new(type:ArgumentType, value:Dynamic)
    {
        this.type = type;
        this.value = value;
    }
}