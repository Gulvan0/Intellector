package client.ui.common.board;

import intellectorboard.primitives.piece.PieceKind;
import intellectorboard.primitives.ply.RawPly;

/** What the user asked of the premove queue (consumed by `Premoves`) **/
enum PremoveIntent
{
    /** `ply.morphInto` is the promotion choice; `morphInto` the chameleon one (`null` for none) **/
    Queue(ply:RawPly, morphInto:Null<PieceKind>);
    CancelAll;
}
