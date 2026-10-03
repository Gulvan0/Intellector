package client.ui.common.board;

/**
    Every color a board is drawn with. Immutable; each entry is a plain color, none derived from
    another. `DEFAULT` holds the defaults; a customized palette is a separate instance.
**/
@:structInit
class BoardPalette
{
    public static final DEFAULT:BoardPalette = {
        baseFill: {light: "#ffcf9f", dark: "#d18b47"},
        border: "#664126",
        fileLetter: "#664126",
        rowNumber: {light: "#664126", dark: "#FFD8B2"},
        moveMarker: "#333333",
        departureHover: {light: "#E56A00", dark: "#E56A00"},
        selectedDeparture: {light: "#E56A00", dark: "#E56A00"},
        destinationHover: {light: "#FFE4C8", dark: "#D9A068"},
        promptAnchor: {light: "#C79A56", dark: "#C79A56"},
        editorHover: {light: "#E56A00", dark: "#E56A00"},
        premove: {light: "#869E60", dark: "#648039"},
        lastMove: {light: "#FDD340", dark: "#BE9C26"},
        annotationFillRed: {light: "#FF6955", dark: "#BE3726"},
        annotationFillBlue: {light: "#83ACD4", dark: "#6F8EAC"},
        annotationFillGreen: {light: "#9DD482", dark: "#83AC6F"},
        annotationFillYellow: {light: "#D4C482", dark: "#ACA06F"},
        annotationMarkRed: "#FF0000",
        annotationMarkBlue: "#0000FF",
        annotationMarkGreen: "#00CC00",
        annotationMarkYellow: "#C8B400"
    };

    public final baseFill:ShadedColor;
    public final border:String;
    public final fileLetter:String;
    // On light / on dark hexes.
    public final rowNumber:ShadedColor;
    public final moveMarker:String;

    public final departureHover:ShadedColor;
    public final selectedDeparture:ShadedColor;
    public final destinationHover:ShadedColor;
    // Theme token accentMuted; the literal accent would hide black pieces.
    public final promptAnchor:ShadedColor;
    public final editorHover:ShadedColor;
    public final premove:ShadedColor;
    public final lastMove:ShadedColor;

    public final annotationFillRed:ShadedColor;
    public final annotationFillBlue:ShadedColor;
    public final annotationFillGreen:ShadedColor;
    public final annotationFillYellow:ShadedColor;

    // Annotation rings and arrows.
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
