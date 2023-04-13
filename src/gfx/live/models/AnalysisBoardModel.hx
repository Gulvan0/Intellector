package gfx.live.models;

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

class AnalysisBoardModel
{
    private var variation:Variation;
    private var selectedNodePath:VariationPath;
    private var orientation:PieceColor;

    private var behaviourType:AnalysisBoardBehaviorType;
    private var boardInteractivityMode:InteractivityMode;

    
}