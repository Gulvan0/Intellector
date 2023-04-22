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
    OfferStateUpdated(kind:OfferKind, direction:OfferDirection, active:Bool);
    MoveAddedToHistory;
    HistoryRollback;

    /* PlannedPremovesUpdated;
    CurrentSituationUpdated;
    InteractivityModeUpdated;
    HistoryRewritten;
    
    PlayerOnlineStatusUpdated;
    SpectatorListUpdated;*/
}