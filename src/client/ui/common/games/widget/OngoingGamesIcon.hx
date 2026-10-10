package client.ui.common.games.widget;

import haxe.ui.backend.html5.svg.SVGPathBuilder;
import haxe.ui.containers.Box;
import haxefolio.graphics.SvgSurface;

/** How strongly the ongoing games widget's icon calls for attention, weakest first **/
enum OngoingGamesSignal
{
    NoGames;
    OpponentMoveOnly;
    CorrespondenceOwnMove;
    TimedOwnMove;
}

/**
    The ongoing games widget's icon: a flower of seven solid hexagons with an Aggressor silhouette over
    it, absent without games, muted while every game waits for the opponent. The silhouette has a halo
    in the colour behind the icon.
**/
class OngoingGamesIcon extends Box
{
    private static inline final SIZE:Float = 24;
    private static inline final HEX_RADIUS:Float = 4.05;
    private static inline final HEX_PITCH:Float = 4.6;
    private static inline final HALO_WIDTH:Float = 0.9;

    // the Aggressor's outer contour, 13 px tall once offset and scaled
    private static inline final PIECE_OUTLINE:String = "M38.06,118.66L31.24,115.66Q23.04,112.05,14.82,108.49L13.15,107.77A66.93,66.93,0,0,0,4.78,104.53C2.42,103.86,0.97,102.83,0.34,101.38S-0.03,98.07,1.19,95.67Q8.59,81.30,15.92,66.89C16.66,65.44,17.41,63.98,18.16,62.52C20.54,57.89,23.00,53.11,25.25,48.34A14.8,14.8,0,0,0,26.25,44.09C26.33,43.51,26.41,42.94,26.50,42.37A14.76,14.76,0,0,0,26.67,40.37A8,8,0,0,1,27.60,36.17C30.51,31.79,28.48,28.39,26.13,24.45L25.88,24.04C22.39,18.25,18.85,12,15.34,5.6C14.52,4.10,14.41,2.82,15.01,1.80S17.07,0.1,19.07,0.08C26.81,0,34.49,0,41.88,0Q50.16,0,58.42,0.05A11.85,11.85,0,0,1,62,0.81C62.62,1,63.28,1.21,64,1.4L65.11,1.69L64.7,2.75C64.43,3.4,64.2,4,64,4.59A28,28,0,0,1,62.49,8C61.25,10.29,59.98,12.55,58.71,14.83C56.21,19.29,53.64,23.89,51.37,28.53C50.82,29.67,51.03,31.39,51.23,33.06C51.31,33.69,51.38,34.31,51.42,34.90A3,3,0,0,0,51.79,35.83A3.6,3.6,0,0,1,52.32,37.83C51.46,44.61,54.48,49.98,57.69,55.66C58.69,57.46,59.73,59.31,60.69,61.18C64.31,68.78,68.31,76.37,72.17,83.7C74.03,87.23,75.89,90.7,77.71,94.3C79.18,97.13,79.86,98.97,79.28,100.57C78.63,102.36,76.56,103.35,73.48,104.64C65.99,107.80,58.42,111.14,51.11,114.38Q46.41,116.46,41.72,118.52L41.53,118.61Z";
    private static inline final PIECE_SCALE:Float = 0.10956;
    private static inline final PIECE_OFFSET_X:Float = 7.65;
    private static inline final PIECE_OFFSET_Y:Float = 5.5;

    private final piece:SVGPathBuilder;

    public function new()
    {
        super();

        width = SIZE;
        height = SIZE;

        var surface:SvgSurface = new SvgSurface(SIZE, SIZE);
        surface.element.setAttribute("aria-hidden", "true");
        addComponent(surface);

        var center:Float = SIZE / 2;
        drawHexagon(surface, center, center);
        for (i in 0...6)
        {
            var angle:Float = Math.PI / 6 + i * Math.PI / 3;
            var distance:Float = HEX_PITCH * Math.sqrt(3);
            drawHexagon(surface, center + distance * Math.cos(angle), center + distance * Math.sin(angle));
        }

        piece = surface.svgPath(0, 0);
        piece.element.setAttribute("d", PIECE_OUTLINE);
        piece.element.setAttribute("transform", 'translate($PIECE_OFFSET_X $PIECE_OFFSET_Y) scale($PIECE_SCALE)');
        piece.element.setAttribute("stroke-width", Std.string(HALO_WIDTH / PIECE_SCALE));
        piece.element.setAttribute("stroke-linejoin", "round");
        piece.element.setAttribute("paint-order", "stroke");

        setSignal(NoGames);
        setOpen(false);
    }

    public function setSignal(signal:OngoingGamesSignal):Void
    {
        piece.element.setAttribute("visibility", signal == NoGames ? "hidden" : "visible");
        piece.element.setAttribute("fill", signal == OpponentMoveOnly ? StyleVars.GAMES_ICON_PIECE_MUTED : StyleVars.GAMES_ICON_PIECE);
    }

    /** The halo follows the target's background, which changes while the dropdown is open **/
    public function setOpen(open:Bool):Void
    {
        piece.element.setAttribute("stroke", open ? StyleVars.GAMES_ICON_HALO_OPEN : StyleVars.GAMES_ICON_HALO);
    }

    // flat-topped, centred at (x, y)
    private static function drawHexagon(surface:SvgSurface, x:Float, y:Float):Void
    {
        var hexagon:SVGPathBuilder = surface.svgPath(x + HEX_RADIUS, y);
        for (i in 1...6)
        {
            var angle:Float = i * Math.PI / 3;
            hexagon.lineTo(x + HEX_RADIUS * Math.cos(angle), y + HEX_RADIUS * Math.sin(angle));
        }
        hexagon.close();
        hexagon.element.setAttribute("fill", StyleVars.GAMES_ICON_HEXAGONS);
    }
}
