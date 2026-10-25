package client.ui;

import client.ui.common.board.BoardSurface;
import haxefolio.ResponsivityController;
import morestd.Detachable;

/**
    The tier scale of the pages built around a board (game, analysis), each tier taken where its
    board comes out large enough. `Rail` takes over every width while the menu bar is a rail (a
    short landscape viewport): the board fills the height beside a narrow column. Otherwise
    independent of the menu bar; pages without a board follow it, or a scale of their own.
**/
enum abstract BoardLayoutTier(String) from String to String
{
    var Compact = "compact";
    var Medium = "medium";
    var Wide = "wide";
    var Rail = "rail";

    /** The scale's name, as registered with HaxeFolio and carried by the `haxefolio-tier-board-<tier>` root classes **/
    public static inline final SCALE:String = "board";

    /** Below it, the medium layout's side column leaves the board too little width to beat the compact one **/
    public static inline final MEDIUM_MIN_WIDTH:Int = 600;
    /** Below this viewport height, a landscape viewport gets the menu bar's rail, and the `Rail` tier **/
    public static inline final RAIL_MAX_HEIGHT:Int = 500;
    /** Any width reaches it, leaving `fitsRail` alone to decide; the wider tiers don't fit a rail viewport, so `Rail` wins over them **/
    public static inline final RAIL_MIN_WIDTH:Int = 1;

    /** Compact: the narrowest the board gets when the viewport is too short for it; the page scrolls instead **/
    public static inline final MIN_COMPACT_BOARD_WIDTH:Float = 260;

    /** The narrowest a stage keeps its control row when it sits above the board, which may be narrower **/
    public static inline final MIN_CONTROL_ROW_WIDTH:Float = 330;

    /** Below it, no viewport height lets the wide board reach `WIDE_BOARD_SHARE` of the medium one **/
    public static inline final WIDE_MIN_WIDTH:Int = 1150;

    private static inline final WIDE_BOARD_SHARE:Float = 0.85;

    /*
        The analysis page's geometry, measured: what the stage loses to the page's insets and side
        columns, and what the board column reserves under the board. Compact: what the board loses
        to the insets, and to everything above and below it with the variations card at its minimum.
    */
    private static inline final COMPACT_BOARD_WIDTH_LOSS:Float = 40;
    private static inline final COMPACT_BOARD_HEIGHT_LOSS:Float = 414;
    private static inline final WIDE_STAGE_WIDTH_LOSS:Float = 692;
    private static inline final MEDIUM_STAGE_WIDTH_LOSS:Float = 366;
    private static inline final STAGE_HEIGHT_LOSS:Float = 82;
    private static inline final WIDE_RESERVED_HEIGHT:Float = 128; // the editor's tool card
    private static inline final MEDIUM_RESERVED_HEIGHT:Float = 45; // the move strip
    private static inline final RAIL_BOARD_WIDTH_LOSS:Float = 260; // the rail's column and the page's insets
    private static inline final RAIL_BOARD_HEIGHT_LOSS:Float = 92; // the menu bar and the page's insets
    // the rail replaces the medium and compact layouts only where its board is this much larger than theirs
    private static inline final RAIL_FALLBACK_BOARD_GAIN:Float = 1.2;

    /** Calls `apply` with the current tier now and whenever it changes; detach the handle on disposal **/
    public static function bind(apply:BoardLayoutTier->Void):Detachable
    {
        return ResponsivityController.bindTier(SCALE, tier -> apply(tier));
    }

    /** Whether a `width`×`height` viewport gets the menu bar's rail **/
    public static function fitsRail(width:Float, height:Float):Bool
    {
        return height < RAIL_MAX_HEIGHT && width > height;
    }

    /** Whether the rail layout is taken: a short landscape viewport, or one where the medium and compact boards come out so small that the rail's beats them clearly **/
    public static function fitsRailTier(width:Float, height:Float):Bool
    {
        if (fitsRail(width, height))
            return true;
        var compactBoardWidth:Float = Math.max(MIN_COMPACT_BOARD_WIDTH, Math.min(width - COMPACT_BOARD_WIDTH_LOSS, (height - COMPACT_BOARD_HEIGHT_LOSS) * aspectRatio()));
        var railBoardWidth:Float = Math.min(width - RAIL_BOARD_WIDTH_LOSS, (height - RAIL_BOARD_HEIGHT_LOSS) * aspectRatio());
        return railBoardWidth >= RAIL_FALLBACK_BOARD_GAIN * Math.max(compactBoardWidth, mediumBoardWidth(width, height));
    }

    /** Whether the medium layout's board is at least as large as the compact one's in a `width`×`height` viewport **/
    public static function fitsMedium(width:Float, height:Float):Bool
    {
        if (fitsRailTier(width, height))
            return false;
        var compactBoardWidth:Float = Math.min(width - COMPACT_BOARD_WIDTH_LOSS, (height - COMPACT_BOARD_HEIGHT_LOSS) * aspectRatio());
        return mediumBoardWidth(width, height) >= compactBoardWidth;
    }

    /** Whether the wide layout's board is at least `WIDE_BOARD_SHARE` of the medium layout's in a `width`×`height` viewport **/
    public static function fitsWide(width:Float, height:Float):Bool
    {
        if (fitsRailTier(width, height))
            return false;
        var wideBoardWidth:Float = Math.min(width - WIDE_STAGE_WIDTH_LOSS, (height - STAGE_HEIGHT_LOSS - WIDE_RESERVED_HEIGHT) * aspectRatio());
        return wideBoardWidth >= WIDE_BOARD_SHARE * mediumBoardWidth(width, height);
    }

    private static function mediumBoardWidth(width:Float, height:Float):Float
    {
        return Math.min(width - MEDIUM_STAGE_WIDTH_LOSS, (height - STAGE_HEIGHT_LOSS - MEDIUM_RESERVED_HEIGHT) * aspectRatio());
    }

    private static function aspectRatio():Float
    {
        return BoardSurface.aspectRatioOf(Preferences.boardCoordinates.get());
    }
}
