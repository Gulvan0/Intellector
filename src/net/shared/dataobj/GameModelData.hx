package net.shared.dataobj;

import net.shared.dataobj.LegacyFlag;
import net.shared.TimeControl;
import net.shared.utils.UnixTimestamp;
import net.shared.board.Situation;
import net.shared.utils.PlayerRef;

typedef GameModelData = {
    //Initial conditions
    var gameID:Int;
    var timeControl:TimeControl;
    var playerRefs:Map<PieceColor, PlayerRef>;
    var elo:Null<Map<PieceColor, EloValue>>;
    var startTimestamp:Null<UnixTimestamp>;
    var startingSituation:Situation;

    var legacyFlags:Array<LegacyFlag>;
    
    //Whole history, should be sorted
    var eventLog:Array<GameEventLogItem>;
    
    //Current state that cannot be deduced from history
    var playerOnline:Map<PieceColor, Bool>;
    var activeSpectators:Array<PlayerRef>;
}