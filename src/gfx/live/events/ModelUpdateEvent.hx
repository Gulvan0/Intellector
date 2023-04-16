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

    /*ShownSituationUpdated;
    PlannedPremovesUpdated;
    CurrentSituationUpdated;
    MoveAddedToHistory;
    HistoryRollback;
    HistoryRewritten;
    OfferActive(kind:OfferKind, direction:OfferDirection);
    OfferInactive(kind:OfferKind, direction:OfferDirection);
    InteractivityModeUpdated;
    
    PlayerOnlineStatusUpdated;
    SpectatorListUpdated;*/
}