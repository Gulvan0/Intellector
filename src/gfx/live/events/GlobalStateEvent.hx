package gfx.live.events;

import gfx.live.OfferDirection;
import gfx.live.OfferKind;

enum GlobalStateEvent 
{
    OrientationUpdated;
    ShownSituationUpdated;
    PlannedPremovesUpdated;
    CurrentSituationUpdated;
    MoveAddedToHistory;
    HistoryRollback;
    HistoryRewritten;
    OfferActive(kind:OfferKind, direction:OfferDirection);
    OfferInactive(kind:OfferKind, direction:OfferDirection);
    TimeDataUpdated;
    ViewedMoveNumUpdated;
    InteractivityModeUpdated;
    EntryAddedToChatHistory;
    PlayerOnlineStatusUpdated;
    SpectatorListUpdated;
}