package gfx.live.interfaces;

import gfx.live.interfaces.IReadOnlySpectationModel;
import net.shared.board.Situation;
import net.shared.Outcome;
import net.shared.EloValue;
import net.shared.PieceColor;
import utils.TimeControl;
import net.shared.utils.PlayerRef;
import gfx.live.interfaces.IReadOnlyMsRemainders;
import gfx.live.struct.MsRemaindersData;
import net.shared.dataobj.TimeReservesData;
import net.shared.board.RawPly;
import gfx.live.interfaces.IReadOnlyHistory;
import net.shared.dataobj.OfferKind;

interface IReadOnlyGameRelatedModel extends IReadOnlyGenericModel
{
    public function getGameID():Int;
    public function getTimeControl():TimeControl;
    public function getPlayerRef(color:PieceColor):PlayerRef;
    public function isRated():Bool;
    public function getELO(color:PieceColor):EloValue;
    public function hasEnded():Bool;
    public function getOutcome():Outcome;
    public function getDateTime():Date;
    public function getHistory():IReadOnlyHistory;
    public function isOutgoingOfferActive(color:PieceColor, kind:OfferKind):Bool;
    public function getTimeReservesData():TimeReservesData;
    public function getMsRemainders():IReadOnlyMsRemainders;
    public function getActiveTimerColor():PieceColor;
    public function getChatHistory():Array<ChatEntry>;
    public function isPlayerOnline(color:PieceColor):Bool;
    public function getSpectators():Array<PlayerRef>;
    public function getPlayerColor():Null<PieceColor>;
}