package net.rest.models.game.request;

import net.rest.models.game.submodels.OfferKind;
import net.rest.models.game.submodels.OfferAction;
import lib.json.IJsonSerializableMacro;

@:structInit
class InternalGamePerformOfferActionPayload implements IJsonSerializableMacro
{
    public var game_id:Int;
    public var action_kind:OfferAction;
    public var offer_kind:OfferKind;
}
