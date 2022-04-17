package struct;

import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;

class TimeCorrectionData
{
    public var whiteSeconds:Float;
    public var blackSeconds:Float;
    public var timestamp:Float;
    public var pingSubtractionSide:String;

    public function new(whiteSeconds:Float, blackSeconds:Float, timestamp:Float, pingSubtractionSide:String)
    {
        this.whiteSeconds = whiteSeconds;
        this.blackSeconds = blackSeconds;
        this.timestamp = timestamp;
        this.pingSubtractionSide = pingSubtractionSide;
    }
}

class ActualizationData 
{
    public var logParserOutput:GameLogParserOutput;
    public var timeCorrectionData:Null<TimeCorrectionData>;

    public static function current(pastLog:String, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, pingSubtractionSide:String):ActualizationData
    {
        return new ActualizationData(pastLog, new TimeCorrectionData(whiteSeconds, blackSeconds, timestamp, pingSubtractionSide));
    }

    public function getColor(login:String) 
    {
        return logParserOutput.getParticipantColor(login);
    }

    public function getPlayerColor() 
    {
        return logParserOutput.getPlayerColor();
    }

    public function new(?pastLog:String, ?timeCorrectionData:Null<TimeCorrectionData>)
    {
        if (pastLog != null)
            this.logParserOutput = GameLogParser.parse(pastLog);
        this.timeCorrectionData = timeCorrectionData;
    }
}