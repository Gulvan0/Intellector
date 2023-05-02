package gfx.live.models;

import net.shared.dataobj.StudyInfo;
import gfx.live.analysis.util.PosEditMode;
import gfx.live.interfaces.IReadOnlyGenericModel;
import gfx.live.interfaces.IReadOnlyAnalysisBoardModel;
import gfx.live.interfaces.ReadOnlyVariation;
import gfx.live.struct.AnalysisBoardBehaviorType;
import net.shared.variation.VariationPath;
import net.shared.variation.Variation;
import gfx.live.interfaces.IReadOnlyMatchVersusPlayerModel;
import net.shared.board.Situation;
import net.shared.Outcome;
import net.shared.EloValue;
import net.shared.PieceColor;
import utils.TimeControl;
import net.shared.utils.PlayerRef;
import gfx.live.interfaces.IReadOnlyMsRemainders;
import gfx.live.struct.MsRemaindersData;
import net.shared.dataobj.TimeReservesData;
import net.shared.board.RawPly;
import gfx.live.interfaces.IReadOnlyHistory;

class AnalysisBoardModel implements IReadOnlyAnalysisBoardModel implements IReadOnlyGenericModel
{
    public var variation:Variation;
    public var selectedBranch:VariationPath;
    public var shownMovePointer:Int;
    public var orientation:PieceColor;

    public var behaviourType:AnalysisBoardBehaviorType;
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

    public function getBehaviourType():AnalysisBoardBehaviorType
    {
        return behaviourType;
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

    public function getExploredStudyID():Null<Int>
    {
        return exploredStudyInfo.id;
    }

    public function getExploredStudyOwnerLogin():Null<String>
    {
        return exploredStudyInfo.ownerLogin;
    }

    //Additional methods to unify with IReadOnlyGenericModel

    public function getCurrentSituation():Situation
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
        return getVariation().getFullMainline(false, model.getSelectedBranch()).map(x -> {ply: x.getIncomingPly(), situationAfter: x.getSituation()});
    }
}