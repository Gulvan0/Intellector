package gfx.game.interfaces;

import engine.Bot;
import net.shared.board.RawPly;

interface IReadOnlyMatchVersusBotModel extends IReadOnlyGameRelatedModel
{
    public function getOpponentBot():Bot;
    public function getPlannedPremoves():Array<RawPly>;
}