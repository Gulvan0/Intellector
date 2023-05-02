package net.shared.dataobj;

import net.shared.board.RawPly;
import net.shared.board.Situation;
import net.shared.utils.PlayerRef;

typedef GameModelData = {
    //Initial conditions
    var gameID:Int;
    var timeControl:{startSecs:Int, bonusSecs:Int};
    var playerRefs:Map<PieceColor, PlayerRef>;
    var elo:Null<Map<PieceColor, EloValue>>;
    var datetime:Null<Date>;
    var startingSituation:Situation;
    
    //Whole history
    var eventLog:Array<{ts:Date, entry:GameEventLogEntry}>;
    
    //Current state that cannot be deduced from history
    var playerOnline:Map<PieceColor, Bool>;
    var activeSpectators:Array<PlayerRef>;
}