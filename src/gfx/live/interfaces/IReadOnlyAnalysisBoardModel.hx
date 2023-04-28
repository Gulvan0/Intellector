package gfx.live.interfaces;

import net.shared.board.Situation;
import gfx.live.struct.AnalysisBoardBehaviorType;
import net.shared.PieceColor;
import net.shared.variation.VariationPath;

interface IReadOnlyAnalysisBoardModel 
{
    public function getVariation():ReadOnlyVariation;
    public function getSelectedBranch():VariationPath;
    public function getShownMovePointer():Int;
    public function getSelectedNodePath():VariationPath;
    public function getSituationAtLineEnd():Situation;
    public function getShownSituation():Situation;
    public function getOrientation():PieceColor;
    public function getBehaviourType():AnalysisBoardBehaviorType;
    public function getBoardInteractivityMode():InteractivityMode;
    public function isEditorActive():Bool;
    public function getEditorSituation():Null<Situation>;
    public function getEditorMode():Null<PosEditMode>;
}