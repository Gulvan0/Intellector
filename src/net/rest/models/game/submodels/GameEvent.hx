package net.rest.models.game.submodels;

import net.rest.models.common.PieceColor;
import net.rest.models.game.submodels.OfferKind;
import net.rest.models.game.submodels.OfferAction;
import net.rest.models.common.UserRefWithNickname;
import net.rest.models.game.submodels.GameTimeUpdatePublic;
import net.rest.models.common.PieceKind;
import net.rest.models.common.HexCoords;
import lib.stdtypes.DateTime;

enum GameEvent
{
    Ply(occuredAt:DateTime, plyIndex:Int, from:HexCoords, to:HexCoords, morphInto:Null<PieceKind>, timeUpdate:Null<GameTimeUpdatePublic>, isCancelled:Bool);
    ChatMessage(occuredAt:DateTime, text:String, spectator:Bool, author:UserRefWithNickname);
    Offer(occuredAt:DateTime, action:OfferAction, kind:OfferKind, author:PieceColor);
    TimeAdded(occuredAt:DateTime, amountSeconds:Int, receiver:PieceColor, timeUpdate:GameTimeUpdatePublic);
    Rollback(occuredAt:DateTime, plyCntBefore:Int, plyCntAfter:Int, requestedBy:PieceColor, timeUpdate:Null<GameTimeUpdatePublic>);
}
