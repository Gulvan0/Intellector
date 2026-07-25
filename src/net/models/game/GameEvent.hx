package net.models.game;

import net.models.common.PieceColor;
import net.models.game.OfferKind;
import net.models.game.OfferAction;
import net.models.common.UserRefWithNickname;
import net.models.game.GameTimeUpdatePublic;
import net.models.common.PieceKind;
import net.models.common.HexCoords;
import morestd.DateTime;

enum GameEvent
{
	Ply(occuredAt:DateTime, event_index:Int, plyIndex:Int, from:HexCoords, to:HexCoords, morphInto:Null<PieceKind>, timeUpdate:Null<GameTimeUpdatePublic>, isCancelled:Bool);
	ChatMessage(occuredAt:DateTime, event_index:Int, text:String, spectator:Bool, author:UserRefWithNickname);
	Offer(occuredAt:DateTime, event_index:Int, action:OfferAction, kind:OfferKind, author:PieceColor);
	TimeAdded(occuredAt:DateTime, event_index:Int, amountSeconds:Int, receiver:PieceColor, timeUpdate:GameTimeUpdatePublic);
	Rollback(occuredAt:DateTime, event_index:Int, plyCntBefore:Int, plyCntAfter:Int, requestedBy:PieceColor, timeUpdate:Null<GameTimeUpdatePublic>);
}
