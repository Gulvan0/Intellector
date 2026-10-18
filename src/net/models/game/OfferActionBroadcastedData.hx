package net.models.game;

import morestd.DateTime;
import jsonmodel.IJsonUnserializableMacro;
import net.models.common.PieceColor;
import net.models.game.OfferAction;
import net.models.game.OfferKind;

class OfferActionBroadcastedData implements IJsonUnserializableMacro
{
	@:jcustomparse(jsonmodel.StdParsers.parseOptionalDate) public var occurred_at:Null<DateTime>;
	public var event_index:Int;
	public var action:OfferAction;
	public var offer_kind:OfferKind;
	public var offer_author:PieceColor;
}
