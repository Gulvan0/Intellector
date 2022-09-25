package gfx.game;

import net.shared.EloValue;
import struct.Situation;
import serialization.GameLogParser.GameLogParserOutput;
import utils.TimeControl;

enum LiveGameConstructor
{
    New(whiteLogin:String, blackLogin:String, whiteELO:EloValue, blackELO:EloValue, timeControl:TimeControl, startingSituation:Situation, startDatetime:Date);
    Ongoing(parsedData:GameLogParserOutput, whiteSeconds:Float, blackSeconds:Float, timeValidAtTimestamp:Float, followedPlayerLogin:Null<String>);
    Past(parsedData:GameLogParserOutput, watchedPlyerLogin:Null<String>);
}