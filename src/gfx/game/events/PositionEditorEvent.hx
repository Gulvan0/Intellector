package gfx.game.events;

import net.shared.board.Situation;
import net.shared.PieceColor;
import gfx.game.analysis.util.PosEditMode;

enum PositionEditorEvent 
{
    EditModeChangeRequested(mode:PosEditMode);
    TurnColorChangeRequested(color:PieceColor);
    SituationImported(situation:Situation);
    ClearRequested;
    ResetRequested;
    StartPosRequested;
    OrientationChangeRequested;
    ApplyChangesRequested;
    DiscardChangesRequested;
}