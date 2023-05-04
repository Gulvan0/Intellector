package gfx.game.events;

import net.shared.dataobj.OfferKind;
import gfx.game.common.action_bar.ActionButton;

enum ActionBarEvent
{
    ActionButtonPressed(btn:ActionButton);
    IncomingOfferAccepted(kind:OfferKind);
    IncomingOfferDeclined(kind:OfferKind);
}