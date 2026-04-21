package net.models.game;

import net.models.common.PieceColor;
import net.models.game.OfferKind;
import net.models.game.OfferAction;
import net.models.common.UserRefWithNickname;
import net.models.game.GameTimeUpdatePublic;
import net.models.common.PieceKind;
import net.models.common.HexCoords;
import lib.std.DateTime;

enum GameEvent
{
	Ply(occuredAt:DateTime, plyIndex:Int, from:HexCoords, to:HexCoords, morphInto:Null<PieceKind>, timeUpdate:Null<GameTimeUpdatePublic>, isCancelled:Bool);
	ChatMessage(occuredAt:DateTime, text:String, spectator:Bool, author:UserRefWithNickname);
	Offer(occuredAt:DateTime, action:OfferAction, kind:OfferKind, author:PieceColor);
	TimeAdded(occuredAt:DateTime, amountSeconds:Int, receiver:PieceColor, timeUpdate:GameTimeUpdatePublic);
	Rollback(occuredAt:DateTime, plyCntBefore:Int, plyCntAfter:Int, requestedBy:PieceColor, timeUpdate:Null<GameTimeUpdatePublic>);
}
