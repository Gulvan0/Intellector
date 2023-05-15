package gfx.game.interfaces;

import net.shared.utils.UnixTimestamp;
import gfx.game.interfaces.IReadOnlySpectationModel;
import net.shared.board.Situation;
import net.shared.Outcome;
import net.shared.EloValue;
import net.shared.PieceColor;
import net.shared.TimeControl;
import net.shared.utils.PlayerRef;
import gfx.game.interfaces.IReadOnlyMsRemainders;
import gfx.game.struct.MsRemaindersData;
import net.shared.dataobj.TimeReservesData;
import net.shared.board.RawPly;
import gfx.game.interfaces.IReadOnlyHistory;
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
    public function getStartTimestamp():UnixTimestamp;
    public function getHistory():IReadOnlyHistory;
    public function isOutgoingOfferActive(color:PieceColor, kind:OfferKind):Bool;
    public function getMsRemainders():Null<IReadOnlyMsRemainders>;
    public function getActiveTimerColor():PieceColor;
    public function getChatHistory():Array<ChatEntry>;
    public function isPlayerOnline(color:PieceColor):Bool;
    public function getSpectators():Array<PlayerRef>;
    public function getPlayerColor():Null<PieceColor>;
}