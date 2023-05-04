package gfx.game.models;

import net.shared.dataobj.StudyInfo;
import gfx.game.analysis.util.PosEditMode;
import gfx.game.interfaces.IReadOnlyAnalysisBoardModel;
import net.shared.variation.ReadOnlyVariation;
import net.shared.variation.VariationPath;
import net.shared.variation.Variation;
import net.shared.board.Situation;
import net.shared.PieceColor;
import net.shared.board.RawPly;

class AnalysisBoardModel implements IReadOnlyAnalysisBoardModel
{
    public var variation:Variation;
    public var selectedBranch:VariationPath;
    public var shownMovePointer:Int;
    public var orientation:PieceColor;

    public var boardInteractivityMode:InteractivityMode;

    public var editorSituation:Null<Situation>;
    public var editorMode:Null<PosEditMode>;

    public var exploredStudyInfo:Null<StudyInfo>;

    public function getVariation():ReadOnlyVariation
    {
        return variation;
    }

    public function getSelectedBranch():VariationPath
    {
        return selectedBranch;
    }

    public function getShownMovePointer():Int
    {
        return shownMovePointer;
    }

    public function getSelectedNodePath():VariationPath
    {
        return selectedBranch.subpath(shownMovePointer);
    }

    public function getShownSituation():Situation
    {
        return variation.getNode(getSelectedNodePath()).situation.copy();
    }

    public function getSituationAtLineEnd():Situation
    {
        return variation.getNode(selectedBranch).situation.copy();
    }

    public function getOrientation():PieceColor
    {
        return orientation;
    }

    public function getBoardInteractivityMode():InteractivityMode
    {
        return boardInteractivityMode;
    }

    public function isEditorActive():Bool
    {
        return editorSituation != null;
    }

    public function getEditorSituation():Null<Situation>
    {
        return editorSituation.copy();
    }

    public function getEditorMode():Null<PosEditMode>
    {
        return editorMode;
    }

    public function getExploredStudyInfo():Null<StudyInfo>
    {
        return exploredStudyInfo;
    }

    //Additional methods to unify with IReadOnlyGenericModel

    public function getMostRecentSituation():Situation
    {
        return getSituationAtLineEnd();
    }

    public function getStartingSituation():Situation
    {
        return getVariation().rootNode().getSituation();
    }
    
    public function getLineLength():Int
    {
        return getSelectedBranch().length;
    }

    public function getLine():Array<{ply:RawPly, situationAfter:Situation}>
    {
        return getVariation().getFullMainline(false, getSelectedBranch()).map(x -> {ply: x.getIncomingPly(), situationAfter: x.getSituation()});
    }

    public function new()
    {

    }
}