package gfx.game;

import net.shared.TimeReservesData;
import net.shared.PieceColor;
import net.shared.EloValue;
import struct.Situation;
import serialization.GameLogParser.GameLogParserOutput;
import utils.TimeControl;

enum LiveGameConstructor
{
    New(whiteLogin:String, blackLogin:String, playerElos:Null<Map<PieceColor, EloValue>>, timeControl:TimeControl, startingSituation:Situation, startDatetime:Date);
    Ongoing(parsedData:GameLogParserOutput, timeData:Null<TimeReservesData>, followedPlayerLogin:Null<String>);
    Past(parsedData:GameLogParserOutput, watchedPlyerLogin:Null<String>);
}