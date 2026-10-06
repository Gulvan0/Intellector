package client.ui.common.board;

/**
    A hex highlight, named by purpose rather than color (`HexTints` maps them to `BoardPalette`
    entries). Declaration order is priority: a hex with several tints shows the first one listed.
**/
enum HexTint
{
    /** A piece that can be picked up, under the cursor **/
    DepartureHover;
    /** A legal destination under the cursor **/
    DestinationHover;
    /** The hex under the cursor in a position editor's place/clear mode **/
    EditorHover;

    /** The departure of the piece currently picked up **/
    SelectedDeparture;
    /** The hex a pending promotion/chameleon prompt is anchored to **/
    PromptAnchor;

    /** An annotated hex, when annotations are shown as fills **/
    AnnotationFill(color:AnnotationColor);

    /** A queued premove's departure or destination **/
    Premove;

    /** The departure and destination of the last move played **/
    LastMove;
}
