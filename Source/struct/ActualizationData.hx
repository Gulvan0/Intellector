package struct;

import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;

typedef TimeCorrectionData = 
{
    public var whiteSeconds:Float;
    public var blackSeconds:Float;
    public var timestamp:Float;
    public var pingSubtractionSide:String;
}

class ActualizationData 
{
    public var logParserOutput:GameLogParserOutput;
    public var timeCorrectionData:Null<TimeCorrectionData>;

    public function new(pastLog:String, ?timeCorrectionData:Null<TimeCorrectionData>)
    {
        this.logParserOutput = GameLogParser.parse(pastLog);
        this.timeCorrectionData = timeCorrectionData;
    }
}