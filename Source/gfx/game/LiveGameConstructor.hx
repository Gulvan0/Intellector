package gfx.game;

import struct.Situation;
import serialization.GameLogParser.GameLogParserOutput;
import utils.TimeControl;

enum LiveGameConstructor
{
    New(whiteLogin:String, blackLogin:String, timeControl:TimeControl, startingSituation:Situation, startDatetime:Date);
    Ongoing(parsedData:GameLogParserOutput, whiteSeconds:Float, blackSeconds:Float, timeValidAtTimestamp:Float, spectatedLogin:Null<String>);
    Past(parsedData:GameLogParserOutput, watchedPlyerLogin:Null<String>);
}