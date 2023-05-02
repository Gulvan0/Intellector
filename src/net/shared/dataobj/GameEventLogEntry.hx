package net.shared.dataobj;

import net.shared.board.RawPly;
import net.shared.dataobj.OfferKind;
import net.shared.PieceColor;
import net.shared.Outcome;
import net.shared.utils.PlayerRef;

enum GameEventLogEntry
{
    Ply(ply:RawPly, whiteMsAfter:Int, blackMsAfter:Int);
    OfferSent(kind:OfferKind, sentBy:PieceColor);
    OfferCancelled(kind:OfferKind, sentBy:PieceColor);
    OfferAccepted(kind:OfferKind, sentBy:PieceColor);
    OfferDeclined(kind:OfferKind, sentBy:PieceColor);
    Message(sentBy:PlayerRef, text:String);
    TimeAdded(receiver:PieceColor);
    GameEnded(outcome:Outcome);
}