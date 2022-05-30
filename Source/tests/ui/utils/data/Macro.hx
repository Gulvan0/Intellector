package tests.ui.utils.data;

import tests.ui.utils.data.MacroStep.constructMacroStep;

class Macro
{
    public var name:String;
    public var sequence:Array<MacroStep>;
    
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

    public function new(name:String, sequence:Array<MacroStep>) 
    {
        this.name = name;
        this.sequence = sequence;
    }
}