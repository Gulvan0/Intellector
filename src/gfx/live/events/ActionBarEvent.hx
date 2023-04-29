package gfx.live.events;

import net.shared.dataobj.OfferKind;
import gfx.live.common.action_bar.ActionButton;

enum ActionBarEvent
{
    ActionButtonPressed(btn:ActionButton);
    IncomingOfferAccepted(kind:OfferKind);
    IncomingOfferDeclined(kind:OfferKind);
}