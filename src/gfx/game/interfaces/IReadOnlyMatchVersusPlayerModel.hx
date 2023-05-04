package gfx.game.interfaces;

import net.shared.board.RawPly;

interface IReadOnlyMatchVersusPlayerModel extends IReadOnlyGameRelatedModel
{
    public function getPlannedPremoves():Array<RawPly>;
    public function isOpponentOnline():Bool;
}