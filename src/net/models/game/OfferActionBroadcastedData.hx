package net.models.game;

import lib.std.DateTime;
import lib.json.IJsonUnserializableMacro;
import net.models.common.PieceColor;
import net.models.game.OfferAction;
import net.models.game.OfferKind;

class OfferActionBroadcastedData implements IJsonUnserializableMacro
{
	@:jcustomparse(lib.json.StdParsers.parseDate) public var occurred_at:DateTime;
	public var action:OfferAction;
	public var offer_kind:OfferKind;
	public var offer_author:PieceColor;
	public var game_id:Int;
}
