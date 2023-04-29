package net.shared.dataobj;

import net.shared.board.RawPly;
import net.shared.board.Situation;
import net.shared.utils.PlayerRef;

typedef GameModelData = {
    var gameID:Int;
    var timeControl:{startSecs:Int, bonusSecs:Int};
    var playerRefs:Map<PieceColor, PlayerRef>;
    var elo:Null<Map<PieceColor, EloValue>>;
    var outcome:Null<Outcome>;
    var datetime:Null<Date>;
    var startingSituation:Situation;
    
    var eventLog:Array<{ts:Date, entry:GameEventLogEntry}>;
    var timeData:TimeReservesData;
    var playerOnline:Map<PieceColor, Bool>;
    var activeSpectators:Array<PlayerRef>;
}