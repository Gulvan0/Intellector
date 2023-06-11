package net.shared.dataobj;

import net.shared.dataobj.OfferAction;
import net.shared.board.RawPly;
import net.shared.dataobj.OfferKind;
import net.shared.PieceColor;
import net.shared.Outcome;
import net.shared.utils.PlayerRef;

enum GameEventLogEntry
{
    Ply(ply:RawPly);
    OfferActionPerformed(kind:OfferKind, sentBy:PieceColor, action:OfferAction);
    Message(sentBy:PlayerRef, text:String);
    TimeAdded(receiver:PieceColor);
    GameEnded(outcome:Outcome);
    Rollback(cancelledMovesCount:Int);
}