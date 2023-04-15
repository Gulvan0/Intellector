package gfx.live.interfaces;

import net.shared.board.Situation;
import gfx.live.struct.AnalysisBoardBehaviorType;
import net.shared.PieceColor;
import net.shared.variation.VariationPath;

interface IReadOnlyAnalysisBoardModel 
{
    public function getVariation():ReadOnlyVariation;
    public function getSelectedNodePath():VariationPath;
    public function getShownSituation():Situation;
    public function getOrientation():PieceColor;
    public function getBehaviourType():AnalysisBoardBehaviorType;
    public function getBoardInteractivityMode():InteractivityMode;
}