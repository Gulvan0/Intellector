package gfx.live.interfaces;

import gfx.live.analysis.util.PosEditMode;
import net.shared.variation.ReadOnlyVariation;
import net.shared.board.Situation;
import gfx.live.struct.AnalysisBoardBehaviorType;
import net.shared.PieceColor;
import net.shared.variation.VariationPath;

interface IReadOnlyAnalysisBoardModel extends IReadOnlyGenericModel
{
    public function getVariation():ReadOnlyVariation;
    public function getSelectedBranch():VariationPath;
    public function getSelectedNodePath():VariationPath;
    public function getSituationAtLineEnd():Situation;
    public function getBehaviourType():AnalysisBoardBehaviorType;
    public function isEditorActive():Bool;
    public function getEditorSituation():Null<Situation>;
    public function getEditorMode():Null<PosEditMode>;
}