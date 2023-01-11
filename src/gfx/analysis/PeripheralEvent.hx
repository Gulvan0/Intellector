package gfx.analysis;

import net.shared.board.RawPly;
import net.shared.board.Situation;
import gfx.utils.PlyScrollType;
import net.shared.PieceColor;

enum PeripheralEvent
{
    BranchSelected(branch:Array<RawPly>, branchStr:Array<String>, pointer:Int);
    RevertNeeded(plyCnt:Int);
    ClearRequested;
    ResetRequested;
    StartPosRequested;
    OrientationChangeRequested;
    ConstructSituationRequested(situation:Situation);
    TurnColorChanged(newTurnColor:PieceColor);
    ApplyChangesRequested;
    DiscardChangesRequested;
    EditModeChanged(newEditMode:PosEditMode);
    EditorLaunchRequested;
    ShareRequested;
    ScrollBtnPressed(type:PlyScrollType);
    PlayFromHereRequested;
}