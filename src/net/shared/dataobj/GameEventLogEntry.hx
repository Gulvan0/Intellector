package net.shared.dataobj;

enum GameEventLogEntry
{
    Ply(ply:RawPly, whiteMsAfter:Int, blackMsAfter:Int);
    OfferSent(kind:OfferKind, sentBy:PieceColor);
    OfferCancelled(kind:OfferKind, sentBy:PieceColor);
    OfferAccepted(kind:OfferKind, sentBy:PieceColor);
    OfferDeclined(kind:OfferKind, sentBy:PieceColor);
}