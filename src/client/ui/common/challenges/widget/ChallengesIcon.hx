package client.ui.common.challenges.widget;

import haxe.ui.backend.html5.svg.SVGPathBuilder;
import haxe.ui.containers.Box;
import haxefolio.graphics.SvgSurface;

/**
    The challenges widget's icon: an outgoing arrow over an incoming one, each lit while there's a
    pending challenge in that direction; the incoming one in the accent colour while there's an
    unseen incoming challenge.
**/
class ChallengesIcon extends Box
{
    private static inline final SIZE:Float = 24;
    private static inline final LIT_STROKE_WIDTH:Float = 2.2;
    private static inline final EMPTY_STROKE_WIDTH:Float = 1.6;
    private static inline final EMPTY_OPACITY:Float = 0.35;

    private final outgoingArrow:SVGPathBuilder;
    private final incomingArrow:SVGPathBuilder;

    public function new()
    {
        super();

        width = SIZE;
        height = SIZE;

        var surface:SvgSurface = new SvgSurface(SIZE, SIZE);
        surface.element.setAttribute("aria-hidden", "true");
        addComponent(surface);

        outgoingArrow = surface.svgPath(3, 7).lineTo(20, 7).moveTo(16, 3).lineTo(20, 7).lineTo(16, 11);
        incomingArrow = surface.svgPath(21, 17).lineTo(4, 17).moveTo(8, 13).lineTo(4, 17).lineTo(8, 21);

        for (arrow in [outgoingArrow, incomingArrow])
        {
            arrow.element.setAttribute("fill", "none");
            arrow.element.setAttribute("stroke-linecap", "round");
            arrow.element.setAttribute("stroke-linejoin", "round");
        }

        setState(false, false, false);
    }

    public function setState(hasIncoming:Bool, hasOutgoing:Bool, hasUnseenIncoming:Bool):Void
    {
        styleArrow(outgoingArrow, hasOutgoing, StyleVars.CHALLENGES_ICON_INK);
        styleArrow(incomingArrow, hasIncoming, hasUnseenIncoming ? StyleVars.CHALLENGES_ICON_ACCENT : StyleVars.CHALLENGES_ICON_INK);
    }

    private static function styleArrow(arrow:SVGPathBuilder, lit:Bool, color:String):Void
    {
        arrow.stroke({color: color, thickness: lit ? LIT_STROKE_WIDTH : EMPTY_STROKE_WIDTH});
        arrow.element.setAttribute("opacity", Std.string(lit ? 1 : EMPTY_OPACITY));
    }
}
