package gfx.live.interfaces;

import net.shared.board.RawPly;
import net.shared.board.Situation;
import net.shared.PieceColor;

interface IReadOnlyGenericModel 
{
    public function getOrientation():PieceColor;
    public function getShownSituation():Situation;
    public function getBoardInteractivityMode():InteractivityMode;
    public function getShownMovePointer():Int;
    public function getCurrentSituation():Situation;
    public function getStartingSituation():Situation;
    public function getLineLength():Int;
    public function getLine():Array<{incomingPly:RawPly, situation:Situation}>;
}