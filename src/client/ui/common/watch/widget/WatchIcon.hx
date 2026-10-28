package client.ui.common.watch.widget;

import client.datatypes.player.PlayerStatus;
import haxe.ui.backend.html5.svg.SVGCircleBuilder;
import haxe.ui.backend.html5.svg.SVGPathBuilder;
import haxe.ui.containers.Box;
import haxefolio.graphics.SvgSurface;

/**
    The watch widget's icon: an eye drawn in strokes, faint while watching no one; while watching,
    lit, its pupil glancing aside, with the watched player's status dot at the lower right, haloed
    in the colour behind the icon.
**/
class WatchIcon extends Box
{
    private static inline final SIZE:Float = 24;
    private static inline final MARGIN:Float = 6; // room around the eye for the status dot, which sticks out at the corner
    private static inline final EYE_OUTLINE:String = "M2.5 12C5 7.6 8.4 5.5 12 5.5S19 7.6 21.5 12C19 16.4 15.6 18.5 12 18.5S5 16.4 2.5 12Z";
    private static inline final PUPIL_RADIUS:Float = 2.8;
    private static inline final LIT_STROKE_WIDTH:Float = 2.2;
    private static inline final EMPTY_STROKE_WIDTH:Float = 1.6;
    private static inline final EMPTY_OPACITY:Float = 0.35;
    private static inline final DOT_X:Float = 23;
    private static inline final DOT_Y:Float = 22;
    private static inline final DOT_RADIUS:Float = 5;
    private static inline final DOT_HALO_WIDTH:Float = 2;
    private static inline final OFFLINE_RING_WIDTH:Float = 1.5;

    private final eye:SVGPathBuilder;
    private final pupil:SVGCircleBuilder;
    private final halo:SVGCircleBuilder;
    private final dot:SVGCircleBuilder;

    private var status:Null<PlayerStatus> = null;
    private var open:Bool = false;

    public function new()
    {
        super();

        width = SIZE + 2 * MARGIN;
        height = SIZE + 2 * MARGIN;

        var surface:SvgSurface = new SvgSurface(SIZE + 2 * MARGIN, SIZE + 2 * MARGIN);
        surface.element.setAttribute("aria-hidden", "true");
        addComponent(surface);

        eye = surface.svgPath(0, 0);
        eye.element.setAttribute("d", EYE_OUTLINE);
        eye.element.setAttribute("fill", "none");
        eye.element.setAttribute("stroke", StyleVars.WATCH_ICON_INK);
        eye.element.setAttribute("stroke-linecap", "round");
        eye.element.setAttribute("stroke-linejoin", "round");

        pupil = surface.svgCircle(0, 0, PUPIL_RADIUS);
        pupil.element.setAttribute("fill", StyleVars.WATCH_ICON_INK);

        halo = surface.svgCircle(DOT_X, DOT_Y, DOT_RADIUS + DOT_HALO_WIDTH);
        dot = surface.svgCircle(DOT_X, DOT_Y, DOT_RADIUS);

        for (shape in [eye.element, pupil.element, halo.element, dot.element])
            shape.setAttribute("transform", 'translate($MARGIN $MARGIN)');

        render();
    }

    /** Null: watching no one **/
    public function setStatus(status:Null<PlayerStatus>):Void
    {
        this.status = status;
        render();
    }

    /** The halo follows the target's background, which changes while the dropdown is open **/
    public function setOpen(open:Bool):Void
    {
        this.open = open;
        render();
    }

    private function render():Void
    {
        var watching:Bool = status != null;
        var opacity:String = Std.string(watching ? 1 : EMPTY_OPACITY);

        eye.element.setAttribute("stroke-width", Std.string(watching ? LIT_STROKE_WIDTH : EMPTY_STROKE_WIDTH));
        eye.element.setAttribute("opacity", opacity);
        pupil.element.setAttribute("cx", Std.string(watching ? 13.2 : 12)); // glancing aside while watching
        pupil.element.setAttribute("cy", Std.string(watching ? 12.8 : 12));
        pupil.element.setAttribute("opacity", opacity);

        var background:String = open ? StyleVars.GAMES_ICON_HALO_OPEN : StyleVars.GAMES_ICON_HALO;
        halo.element.setAttribute("visibility", watching ? "visible" : "hidden");
        halo.element.setAttribute("fill", background);
        dot.element.setAttribute("visibility", watching ? "visible" : "hidden");

        if (status == Offline)
        {
            dot.element.setAttribute("r", Std.string(DOT_RADIUS - OFFLINE_RING_WIDTH / 2));
            dot.element.setAttribute("fill", background);
            dot.element.setAttribute("stroke", StyleVars.WATCH_ICON_OFFLINE_RING);
            dot.element.setAttribute("stroke-width", Std.string(OFFLINE_RING_WIDTH));
        }
        else
        {
            dot.element.setAttribute("r", Std.string(DOT_RADIUS));
            dot.element.setAttribute("fill", dotColor(status));
            dot.element.setAttribute("stroke", "none");
        }
    }

    private static function dotColor(status:Null<PlayerStatus>):String
    {
        return switch status {
            case Playing: StyleVars.WATCH_ICON_PLAYING;
            case Away: StyleVars.WATCH_ICON_AWAY;
            default: StyleVars.WATCH_ICON_ONLINE;
        }
    }
}
