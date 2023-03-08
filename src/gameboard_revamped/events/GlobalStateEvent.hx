package gameboard_revamped.events;

import gameboard_revamped.OfferDirection;
import gameboard_revamped.OfferKind;

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
}