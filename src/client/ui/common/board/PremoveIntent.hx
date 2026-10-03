package client.ui.common.board;

import intellectorboard.primitives.piece.PieceKind;
import intellectorboard.primitives.ply.RawPly;

/**
    What the user asked of the premove queue (consumed by `Premoves`).
**/
enum PremoveIntent
{
    /*
        Adds `ply` (its `morphInto` being the promotion choice, if any) to the queue. `morphInto`
        is the chameleon choice: `null` for none.
    */
    Queue(ply:RawPly, morphInto:Null<PieceKind>);
    CancelAll;
}
