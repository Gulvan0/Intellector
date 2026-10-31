package client.ui.common;

import haxe.ui.backend.html5.svg.SVGCircleBuilder;
import haxe.ui.backend.html5.svg.SVGPathBuilder;
import haxe.ui.containers.Box;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import haxefolio.graphics.SvgSurface;

/**
    A 16px brass eye beside a nickname, shown while the user watches that player, with a tooltip
    saying so.
**/
class WatchEye extends Box
{
    private static inline final SIZE:Float = 16;
    private static inline final VIEW_BOX_SIZE:Float = 24; // the watch widget icon's
    private static inline final OUTLINE:String = "M2.5 12C5 7.6 8.4 5.5 12 5.5S19 7.6 21.5 12C19 16.4 15.6 18.5 12 18.5S5 16.4 2.5 12Z";
    private static inline final PUPIL_RADIUS:Float = 2.8;
    private static inline final STROKE_WIDTH:Float = 1.9;

    private var userRef:Null<String> = null;
    private var nickname:String = "";

    public function new()
    {
        super();

        width = SIZE;
        height = SIZE;
        verticalAlign = "center";
        hidden = true;
        element.setAttribute("role", "img");

        var surface:SvgSurface = new SvgSurface(VIEW_BOX_SIZE, VIEW_BOX_SIZE);
        surface.percentWidth = 100; // scaled down from the view box
        surface.element.setAttribute("aria-hidden", "true");
        addComponent(surface);

        var outline:SVGPathBuilder = surface.svgPath(0, 0);
        outline.element.setAttribute("d", OUTLINE);
        outline.element.setAttribute("fill", "none");
        outline.element.setAttribute("stroke", StyleVars.WATCHED_PLAYER_EYE);
        outline.element.setAttribute("stroke-width", Std.string(STROKE_WIDTH));
        outline.element.setAttribute("stroke-linecap", "round");
        outline.element.setAttribute("stroke-linejoin", "round");

        var pupil:SVGCircleBuilder = surface.svgCircle(VIEW_BOX_SIZE / 2, VIEW_BOX_SIZE / 2, PUPIL_RADIUS);
        pupil.element.setAttribute("fill", StyleVars.WATCHED_PLAYER_EYE);
    }

    /** The user whose nickname it stands beside **/
    public function setUser(userRef:String, nickname:String, watchedLogin:Null<String>):Void
    {
        this.userRef = userRef;
        this.nickname = nickname;
        LocaleManager.instance.registerComponent(this, "tooltip", resolveText);
        setWatchedLogin(watchedLogin);
    }

    /** `watchedLogin`: the watched player's, null while watching no one **/
    public function setWatchedLogin(watchedLogin:Null<String>):Void
    {
        hidden = userRef == null || userRef != watchedLogin;
        element.setAttribute("aria-label", resolveText());
    }

    private function resolveText():String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.live_game.watched_player"), LocaleUtils.resolveText(nickname));
    }
}
