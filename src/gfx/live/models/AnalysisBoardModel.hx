package gfx.live.models;

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

class AnalysisBoardModel implements IReadOnlyAnalysisBoardModel
{
    private var variation:Variation;
    private var selectedNodePath:VariationPath;
    private var orientation:PieceColor;

    private var behaviourType:AnalysisBoardBehaviorType;
    private var boardInteractivityMode:InteractivityMode;

    public function getVariation():ReadOnlyVariation
    {
        return variation;
    }

    public function getMultableVariation():Variation
    {
        return variation;
    }

    public function getSelectedNodePath():VariationPath
    {
        return selectedNodePath;
    }

    public function getShownSituation():Situation
    {
        return variation.getNode(selectedNodePath).situation.copy();
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
}