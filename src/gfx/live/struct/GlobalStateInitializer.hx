package gfx.live.struct;

import struct.Variant;
import net.shared.dataobj.TimeReservesData;
import net.shared.board.Situation;
import net.shared.PieceColor;
import net.shared.EloValue;
import serialization.GameLogParser.GameLogParserOutput;
import utils.TimeControl;

enum GlobalStateInitializer
{
    New(parsedData:GameLogParserOutput);
    Ongoing(parsedData:GameLogParserOutput, timeData:Null<TimeReservesData>, followedPlayerLogin:Null<String>);
    Past(parsedData:GameLogParserOutput, watchedPlyerLogin:Null<String>);
    Analysis(initialVariant:Variant, selectedBranch:VariantPath, shownMoveNum:Int);
}