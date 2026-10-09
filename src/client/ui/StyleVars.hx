package client.ui;

import haxefolio.Shadow;
import haxefolio.appearance.PartialShadowTokens;

class StyleVars
{
    private static inline final SHADOW_COLOR:Int = 0x2A211A; // the theme's ink

    /** HaxeFolio's own shadows, tinted with the theme's ink **/
    public static final HAXEFOLIO_SHADOWS:PartialShadowTokens = {
        dialog: {offsetX: 0, offsetY: 8, blur: 28, color: SHADOW_COLOR, opacity: 0.16},
        sheet: {offsetX: 0, offsetY: -4, blur: 20, color: SHADOW_COLOR, opacity: 0.18},
        sideBar: {offsetX: 4, offsetY: 0, blur: 20, color: SHADOW_COLOR, opacity: 0.18},
        menuDropdown: {offsetX: 0, offsetY: 8, blur: 28, color: SHADOW_COLOR, opacity: 0.16},
        notificationCard: {offsetX: 0, offsetY: 8, blur: 28, color: SHADOW_COLOR, opacity: 0.16}
    };

    public static inline final CHALLENGE_STACK_EXPANDED_WIDTH:Int = 340;
    public static final CHALLENGE_ROW_SHADOW:Shadow = {offsetX: 0, offsetY: 2, blur: 10, color: SHADOW_COLOR, opacity: 0.08};
    public static final CHALLENGE_PREVIEW_SHADOW:Shadow = {offsetX: 0, offsetY: 8, blur: 28, color: SHADOW_COLOR, opacity: 0.16};

    public static inline final BOARD_DEFAULT_BASE_FILL_LIGHT:String = "#ffcf9f";
    public static inline final BOARD_DEFAULT_BASE_FILL_DARK:String = "#d18b47";
    public static inline final BOARD_DEFAULT_BORDER:String = "#664126";
    public static inline final BOARD_DEFAULT_FILE_LETTER:String = "#664126";
    public static inline final BOARD_DEFAULT_ROW_NUMBER_LIGHT:String = "#664126";
    public static inline final BOARD_DEFAULT_ROW_NUMBER_DARK:String = "#FFD8B2";
    public static inline final BOARD_DEFAULT_MOVE_MARKER:String = "#333333";
    public static inline final BOARD_DEFAULT_DEPARTURE_HOVER_LIGHT:String = "#E56A00";
    public static inline final BOARD_DEFAULT_DEPARTURE_HOVER_DARK:String = "#E56A00";
    public static inline final BOARD_DEFAULT_SELECTED_DEPARTURE_LIGHT:String = "#E56A00";
    public static inline final BOARD_DEFAULT_SELECTED_DEPARTURE_DARK:String = "#E56A00";
    public static inline final BOARD_DEFAULT_DESTINATION_HOVER_LIGHT:String = "#FFE4C8";
    public static inline final BOARD_DEFAULT_DESTINATION_HOVER_DARK:String = "#D9A068";
    public static inline final BOARD_DEFAULT_PROMPT_ANCHOR_LIGHT:String = "#C79A56"; // the muted accent: the full one would hide black pieces
    public static inline final BOARD_DEFAULT_PROMPT_ANCHOR_DARK:String = "#C79A56";
    public static inline final BOARD_DEFAULT_EDITOR_HOVER_LIGHT:String = "#E56A00";
    public static inline final BOARD_DEFAULT_EDITOR_HOVER_DARK:String = "#E56A00";
    public static inline final BOARD_DEFAULT_PREMOVE_LIGHT:String = "#869E60";
    public static inline final BOARD_DEFAULT_PREMOVE_DARK:String = "#648039";
    public static inline final BOARD_DEFAULT_LAST_MOVE_LIGHT:String = "#FDD340";
    public static inline final BOARD_DEFAULT_LAST_MOVE_DARK:String = "#BE9C26";
    public static inline final BOARD_DEFAULT_ANNOTATION_FILL_RED_LIGHT:String = "#FF6955";
    public static inline final BOARD_DEFAULT_ANNOTATION_FILL_RED_DARK:String = "#BE3726";
    public static inline final BOARD_DEFAULT_ANNOTATION_FILL_BLUE_LIGHT:String = "#83ACD4";
    public static inline final BOARD_DEFAULT_ANNOTATION_FILL_BLUE_DARK:String = "#6F8EAC";
    public static inline final BOARD_DEFAULT_ANNOTATION_FILL_GREEN_LIGHT:String = "#9DD482";
    public static inline final BOARD_DEFAULT_ANNOTATION_FILL_GREEN_DARK:String = "#83AC6F";
    public static inline final BOARD_DEFAULT_ANNOTATION_FILL_YELLOW_LIGHT:String = "#D4C482";
    public static inline final BOARD_DEFAULT_ANNOTATION_FILL_YELLOW_DARK:String = "#ACA06F";
    public static inline final BOARD_DEFAULT_ANNOTATION_MARK_RED:String = "#FF0000";
    public static inline final BOARD_DEFAULT_ANNOTATION_MARK_BLUE:String = "#0000FF";
    public static inline final BOARD_DEFAULT_ANNOTATION_MARK_GREEN:String = "#00CC00";
    public static inline final BOARD_DEFAULT_ANNOTATION_MARK_YELLOW:String = "#C8B400";

    public static inline final BOARD_ARROW_TRUNK_THICKNESS_SLU:Float = 0.375;
    public static inline final BOARD_ARROW_CAP_SIDE_SLU:Float = 0.75;
    public static inline final BOARD_ARROW_START_OFFSET_SLU:Float = 0.5; // halfway from the source hex's center to its corners
    public static inline final BOARD_ANNOTATION_OPACITY:Float = 0.75;
    public static inline final BOARD_ANNOTATION_RING_RADIUS_SLU:Float = 1; // through the hex's vertices: a hex's circumradius is its side length
    public static inline final BOARD_ANNOTATION_RING_THICKNESS_SLU:Float = 0.24;
    public static inline final BOARD_MARKER_DOT_RADIUS_SLU:Float = 0.2;
    public static inline final BOARD_MARKER_RING_RADIUS_SLU:Float = 0.8;
    public static inline final BOARD_MARKER_RING_THICKNESS_SLU:Float = 0.1;
    public static inline final BOARD_ROW_NUMBER_FONT_SIZE_SLU:Float = 0.35;
    public static inline final BOARD_ROW_NUMBER_INSET_SLU:Float = 0.85; // from the hex's center to the number's left edge
    public static inline final BOARD_FILE_LETTER_FONT_SIZE_SLU:Float = 0.7;
    public static inline final BOARD_FILE_LETTER_GAP_SLU:Float = 0.04;
    public static inline final BOARD_FILE_LETTER_ROW_HEIGHT_SLU:Float = 1.3 * BOARD_FILE_LETTER_FONT_SIZE_SLU;

    public static inline final BOARD_PIECE_HEIGHT_SHARE:Float = 0.85;
    public static inline final BOARD_PROGRESSOR_SCALE:Float = 0.7;
    public static inline final BOARD_LIBERATOR_SCALE:Float = 0.9;
    public static inline final BOARD_DEFENSOR_SCALE:Float = 0.9;

    public static inline final MOVE_PROMPT_SCRIM_COLOR:String = "rgba(42, 33, 26, 0.1)";
    public static inline final MOVE_PROMPT_SCRIM_WHEEL_LINE_HEIGHT:Float = 16; // pixels per line for a line-mode wheel scroll

    public static inline final LOGIN_OVERLAY_WIDTH:Int = 430;
    public static inline final LOGIN_OVERLAY_HEIGHT:Int = 413;

    public static inline final BOARD_CONTROL_BUTTON_WIDTH:Float = 40;
    public static inline final BOARD_CONTROL_BUTTON_HEIGHT:Float = 36;
    public static inline final BOARD_CONTROL_BUTTON_RADIUS:Float = 5;
    public static inline final BOARD_CONTROL_COLOR_DISC_SIZE:Float = 22;
    public static inline final BOARD_CONTROL_ART_SIZE:Float = 28;
    public static inline final BOARD_CONTROL_CHAMELEON_ICON_SIZE:Float = BOARD_CONTROL_ART_SIZE + 8;

    public static inline final MOVE_PROMPT_SLOT_SHARE:Float = 0.72; // of a round button's diameter taken by its art slot
    public static inline final MOVE_PROMPT_ART_SHARE:Float = 0.76; // of the slot taken by the art
    public static inline final MOVE_PROMPT_CROSS_SHARE:Float = 0.4; // of a round button's diameter taken by the cross

    public static final MOVE_PROMPT_RING_SHADOW:Shadow = {offsetX: 0, offsetY: 4, blur: 14, color: SHADOW_COLOR, opacity: 0.18};
    public static final MOVE_PROMPT_POPOVER_SHADOW:Shadow = {offsetX: 0, offsetY: 8, blur: 28, color: SHADOW_COLOR, opacity: 0.16};
    public static inline final MOVE_PROMPT_VIEWPORT_MARGIN:Float = 8;
    public static inline final MOVE_PROMPT_RING_GAP:Float = 6;
    public static inline final MOVE_PROMPT_RING_MINIMUM_DIAMETER:Float = 44;
    public static inline final MOVE_PROMPT_RING_DIAMETER_SHARE:Float = 0.9; // of the hex's on-screen height: the button's radius is close to the hex's inner one
    public static inline final MOVE_PROMPT_MORPH_POPOVER_WIDTH:Int = 390;
    public static inline final MOVE_PROMPT_MORPH_BUTTON_HEIGHT:Int = 84;
    public static inline final MOVE_PROMPT_MORPH_ART_SLOT_DIAMETER:Int = 60;
    public static inline final MOVE_PROMPT_MORPH_CLOSE_SIZE:Int = 42;
    public static inline final MOVE_PROMPT_MORPH_CLOSE_FONT_SIZE:Int = 21;
    public static inline final MOVE_PROMPT_MORPH_CLOSE_RADIUS:Int = 6;
    public static inline final MOVE_PROMPT_MORPH_ANCHOR_GAP:Float = 12;
    public static inline final MOVE_PROMPT_MORPH_ESTIMATED_HEIGHT:Float = 264; // until the popover is laid out and can be measured
}
