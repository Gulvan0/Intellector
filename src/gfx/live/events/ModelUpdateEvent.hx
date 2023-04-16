package gfx.live.events;

import gfx.live.OfferDirection;
import gfx.live.OfferKind;

enum ModelUpdateEvent 
{
    OrientationUpdated;
    EntryAddedToChatHistory;
    GameEnded;
    ViewedMoveNumUpdated;
    TimeDataUpdated;
    ActiveTimerColorUpdated;
    ShownSituationUpdated;

    /* PlannedPremovesUpdated;
    CurrentSituationUpdated;
    OfferActive(kind:OfferKind, direction:OfferDirection);
    OfferInactive(kind:OfferKind, direction:OfferDirection);
    InteractivityModeUpdated;
    MoveAddedToHistory;
    HistoryRollback;
    HistoryRewritten;
    
    PlayerOnlineStatusUpdated;
    SpectatorListUpdated;*/
}