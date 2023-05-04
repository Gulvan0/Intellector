package gfx.game.interfaces;

import net.shared.board.RawPly;
import net.shared.board.Situation;
import net.shared.PieceColor;

interface IReadOnlyGenericModel 
{
    public function getOrientation():PieceColor;
    public function getShownSituation():Situation;
    public function getBoardInteractivityMode():InteractivityMode;
    public function getShownMovePointer():Int;
    public function getMostRecentSituation():Situation;
    public function getStartingSituation():Situation;
    public function getLineLength():Int;
    public function getLine():Array<{ply:RawPly, situationAfter:Situation}>;
}