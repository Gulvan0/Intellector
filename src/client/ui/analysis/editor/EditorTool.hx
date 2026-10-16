package client.ui.analysis.editor;

import intellectorboard.primitives.piece.PieceData;

/** What the position editor's primary button does on the board **/
enum EditorTool
{
    FreeMove;
    Place(piece:PieceData);
    DeletePiece;
}
