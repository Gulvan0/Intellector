package gfx.live.struct;

import serialization.GameLogParser.GameLogParserOutput;
import net.shared.board.Situation;
import net.shared.Outcome;
import net.shared.EloValue;
import net.shared.PieceColor;
import utils.TimeControl;
import net.shared.utils.PlayerRef;

class ConstantGameParameters 
{
    public final timeControl:TimeControl;
    public final playerRefs:Map<PieceColor, PlayerRef>;
    public final elo:Null<Map<PieceColor, EloValue>>;
    public final outcome:Null<Outcome>;
    public final datetime:Null<Date>;
    public final startingSituation:Situation;

    public function new(parsedLog:GameLogParserOutput) 
    {
        this.timeControl = parsedLog.timeControl;
        this.playerRefs = [White => parsedLog.whiteRef, Black => parsedLog.blackRef];
        this.elo = parsedLog.elo;
        this.outcome = parsedLog.outcome;
        this.datetime = parsedLog.datetime;
        this.startingSituation = parsedLog.startingSituation;
    }
}