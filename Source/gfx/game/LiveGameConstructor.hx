package gfx.game;

import struct.Situation;
import serialization.GameLogParser.GameLogParserOutput;
import utils.TimeControl;

enum LiveGameConstructor
{
    New(whiteLogin:String, blackLogin:String, timeControl:TimeControl, startingSituation:Null<Situation>);
    Ongoing(parsedData:GameLogParserOutput, whiteSeconds:Float, blackSeconds:Float, timeValidAtTimestamp:Float);
    Past(parsedData:GameLogParserOutput);
}