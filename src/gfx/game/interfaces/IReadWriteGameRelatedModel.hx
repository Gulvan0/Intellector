package gfx.game.interfaces;

import gfx.game.models.util.ChatEntry;
import gfx.game.models.util.History;
import net.shared.Outcome;
import gfx.game.models.util.MsRemaindersData;
import net.shared.PieceColor;
import net.shared.utils.PlayerRef;
import net.shared.utils.UnixTimestamp;
import net.shared.TimeControl;

interface IReadWriteGameRelatedModel extends IReadOnlyGameRelatedModel extends IReadWriteGenericModel
{
    public var gameID:Int;
    public var timeControl:TimeControl;
    public var playerRefs:Map<PieceColor, PlayerRef>;
    public var outcome:Null<Outcome>;
    public var startTimestamp:Null<UnixTimestamp>;
    
    public var history:History;
    public var perMoveTimeRemaindersData:Null<MsRemaindersData>;

    public var chatHistory:Array<ChatEntry>;
    public var spectatorRefs:Array<PlayerRef>;   
}