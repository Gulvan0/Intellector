package client.ui.common.board;

/** Every color a board is drawn with; a customized palette is a separate instance **/
@:structInit
class BoardPalette
{
    public static final DEFAULT:BoardPalette = {
        baseFill: {light: StyleVars.BOARD_DEFAULT_BASE_FILL_LIGHT, dark: StyleVars.BOARD_DEFAULT_BASE_FILL_DARK},
        border: StyleVars.BOARD_DEFAULT_BORDER,
        fileLetter: StyleVars.BOARD_DEFAULT_FILE_LETTER,
        rowNumber: {light: StyleVars.BOARD_DEFAULT_ROW_NUMBER_LIGHT, dark: StyleVars.BOARD_DEFAULT_ROW_NUMBER_DARK},
        moveMarker: StyleVars.BOARD_DEFAULT_MOVE_MARKER,
        departureHover: {light: StyleVars.BOARD_DEFAULT_DEPARTURE_HOVER_LIGHT, dark: StyleVars.BOARD_DEFAULT_DEPARTURE_HOVER_DARK},
        selectedDeparture: {light: StyleVars.BOARD_DEFAULT_SELECTED_DEPARTURE_LIGHT, dark: StyleVars.BOARD_DEFAULT_SELECTED_DEPARTURE_DARK},
        destinationHover: {light: StyleVars.BOARD_DEFAULT_DESTINATION_HOVER_LIGHT, dark: StyleVars.BOARD_DEFAULT_DESTINATION_HOVER_DARK},
        promptAnchor: {light: StyleVars.BOARD_DEFAULT_PROMPT_ANCHOR_LIGHT, dark: StyleVars.BOARD_DEFAULT_PROMPT_ANCHOR_DARK},
        editorHover: {light: StyleVars.BOARD_DEFAULT_EDITOR_HOVER_LIGHT, dark: StyleVars.BOARD_DEFAULT_EDITOR_HOVER_DARK},
        premove: {light: StyleVars.BOARD_DEFAULT_PREMOVE_LIGHT, dark: StyleVars.BOARD_DEFAULT_PREMOVE_DARK},
        lastMove: {light: StyleVars.BOARD_DEFAULT_LAST_MOVE_LIGHT, dark: StyleVars.BOARD_DEFAULT_LAST_MOVE_DARK},
        annotationFillRed: {light: StyleVars.BOARD_DEFAULT_ANNOTATION_FILL_RED_LIGHT, dark: StyleVars.BOARD_DEFAULT_ANNOTATION_FILL_RED_DARK},
        annotationFillBlue: {light: StyleVars.BOARD_DEFAULT_ANNOTATION_FILL_BLUE_LIGHT, dark: StyleVars.BOARD_DEFAULT_ANNOTATION_FILL_BLUE_DARK},
        annotationFillGreen: {light: StyleVars.BOARD_DEFAULT_ANNOTATION_FILL_GREEN_LIGHT, dark: StyleVars.BOARD_DEFAULT_ANNOTATION_FILL_GREEN_DARK},
        annotationFillYellow: {light: StyleVars.BOARD_DEFAULT_ANNOTATION_FILL_YELLOW_LIGHT, dark: StyleVars.BOARD_DEFAULT_ANNOTATION_FILL_YELLOW_DARK},
        annotationMarkRed: StyleVars.BOARD_DEFAULT_ANNOTATION_MARK_RED,
        annotationMarkBlue: StyleVars.BOARD_DEFAULT_ANNOTATION_MARK_BLUE,
        annotationMarkGreen: StyleVars.BOARD_DEFAULT_ANNOTATION_MARK_GREEN,
        annotationMarkYellow: StyleVars.BOARD_DEFAULT_ANNOTATION_MARK_YELLOW
    };

    public final baseFill:ShadedColor;
    public final border:String;
    public final fileLetter:String;
    public final rowNumber:ShadedColor;
    public final moveMarker:String;

    public final departureHover:ShadedColor;
    public final selectedDeparture:ShadedColor;
    public final destinationHover:ShadedColor;
    public final promptAnchor:ShadedColor;
    public final editorHover:ShadedColor;
    public final premove:ShadedColor;
    public final lastMove:ShadedColor;

    public final annotationFillRed:ShadedColor;
    public final annotationFillBlue:ShadedColor;
    public final annotationFillGreen:ShadedColor;
    public final annotationFillYellow:ShadedColor;

    /** Annotation rings and arrows **/
    public final annotationMarkRed:String;
    public final annotationMarkBlue:String;
    public final annotationMarkGreen:String;
    public final annotationMarkYellow:String;

    public function annotationFill(color:AnnotationColor):ShadedColor
    {
        return switch color {
            case Red: annotationFillRed;
            case Blue: annotationFillBlue;
            case Green: annotationFillGreen;
            case Yellow: annotationFillYellow;
        }
    }

    public function annotationMark(color:AnnotationColor):String
    {
        return switch color {
            case Red: annotationMarkRed;
            case Blue: annotationMarkBlue;
            case Green: annotationMarkGreen;
            case Yellow: annotationMarkYellow;
        }
    }
}
