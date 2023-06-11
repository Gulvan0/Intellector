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
    OfferStateUpdated(kind:OfferKind, direction:OfferDirection, active:Bool);
    MoveAddedToHistory;
    HistoryRollback;
    HistoryRewritten;
    VariationUpdated;
    SelectedVariationNodeUpdated;
    EditorSituationUpdated;
    EditorModeUpdated;
    InteractivityModeUpdated;
    PlannedPremovesUpdated;
    PlayerOnlineStatusUpdated;
    SpectatorListUpdated;
    ShownSituationUpdated;
}