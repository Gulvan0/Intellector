package gfx.live.events;

import net.shared.board.Situation;
import net.shared.PieceColor;
import gfx.live.analysis.util.PosEditMode;

enum PositionEditorEvent 
{
    EditModeChangeRequested(mode:PosEditMode);
    TurnColorChangeRequested(color:PieceColor);
    SituationImported(situation:Situation);
    ApplyChangesRequested;
    DiscardChangesRequested;
}