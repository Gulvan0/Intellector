package gfx.analysis;

import gfx.utils.PlyScrollType;
import struct.PieceColor;
import struct.Situation;
import struct.Ply;

enum PeripheralEvent
{
    BranchSelected(branch:Array<Ply>, branchStr:Array<String>, pointer:Int);
    RevertNeeded(plyCnt:Int);
    ClearRequested;
    ResetRequested;
    StartPosRequested;
    OrientationChangeRequested;
    ConstructSituationRequested(situation:Situation);
    TurnColorChanged(newTurnColor:PieceColor);
    ApplyChangesRequested(turnColor:PieceColor);
    DiscardChangesRequested;
    EditModeChanged(newEditMode:PosEditMode);
    EditorLaunchRequested;
    ShareRequested;
    ScrollBtnPressed(type:PlyScrollType);
}