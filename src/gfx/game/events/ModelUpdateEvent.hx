package gfx.game.events;

import net.shared.dataobj.OfferDirection;
import net.shared.dataobj.OfferKind;

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
    HistoryRewritten;
    EditorActivenessUpdated;
    VariationUpdated;
    SelectedVariationNodeUpdated;
    EditorSituationUpdated;
    EditorModeUpdated;
    InteractivityModeUpdated;
    PlannedPremovesUpdated;
    PlayerOnlineStatusUpdated;
    SpectatorListUpdated;
}