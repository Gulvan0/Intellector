package net.models.game.internal;

import net.models.game.OfferKind;
import net.models.game.OfferAction;
import jsonmodel.IJsonSerializableMacro;

@:structInit
class InternalGamePerformOfferActionPayload implements IJsonSerializableMacro
{
	public var game_id:Int;
	public var action_kind:OfferAction;
	public var offer_kind:OfferKind;
}
