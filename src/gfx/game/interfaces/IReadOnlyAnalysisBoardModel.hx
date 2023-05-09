package gfx.game.interfaces;

import net.shared.dataobj.StudyInfo;
import gfx.game.analysis.util.PosEditMode;
import net.shared.variation.ReadOnlyVariation;
import net.shared.board.Situation;
import net.shared.PieceColor;
import net.shared.variation.VariationPath;

interface IReadOnlyAnalysisBoardModel extends IReadOnlyGenericModel
{
    public function getVariation():ReadOnlyVariation;
    public function getSelectedBranch():VariationPath;
    public function getSelectedNodePath():VariationPath;
    public function getSituationAtLineEnd():Situation;
    public function isEditorActive():Bool;
    public function getEditorSituation():Null<Situation>;
    public function getEditorMode():Null<PosEditMode>;
    public function getExploredStudyInfo():Null<StudyInfo>;
}