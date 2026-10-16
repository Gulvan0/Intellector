package client.ui;

import client.ui.common.board.BoardSurface;
import haxefolio.ResponsivityController;
import morestd.Detachable;

/**
    The tier scale of the pages built around a board (game, analysis), each tier taken where its
    board comes out large enough. Independent of the menu bar's collapse; pages without a board
    follow that, or a scale of their own.
**/
enum abstract BoardLayoutTier(String) from String to String
{
    var Compact = "compact";
    var Medium = "medium";
    var Wide = "wide";

    /** The scale's name, as registered with HaxeFolio and carried by the `haxefolio-tier-board-<tier>` root classes **/
    public static inline final SCALE:String = "board";

    /** Below it, the medium layout's side column leaves the board too little width to beat the compact one **/
    public static inline final MEDIUM_MIN_WIDTH:Int = 600;
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

    /** Calls `apply` with the current tier now and whenever it changes; detach the handle on disposal **/
    public static function bind(apply:BoardLayoutTier->Void):Detachable
    {
        return ResponsivityController.bindTier(SCALE, tier -> apply(tier));
    }

    /** Whether the medium layout's board is at least as large as the compact one's in a `width`×`height` viewport **/
    public static function fitsMedium(width:Float, height:Float):Bool
    {
        var compactBoardWidth:Float = Math.min(width - COMPACT_BOARD_WIDTH_LOSS, (height - COMPACT_BOARD_HEIGHT_LOSS) * aspectRatio());
        return mediumBoardWidth(width, height) >= compactBoardWidth;
    }

    /** Whether the wide layout's board is at least `WIDE_BOARD_SHARE` of the medium layout's in a `width`×`height` viewport **/
    public static function fitsWide(width:Float, height:Float):Bool
    {
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
