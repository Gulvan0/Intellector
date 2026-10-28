package client.ui.common.notifications;

import client.formatters.ClockFormatters;
import haxe.Timer;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.core.Screen;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import js.Browser;
import js.html.Animation;
import js.html.DivElement;
import js.html.FillMode;

/**
    Tells the user that the server connection is lost, once it stays lost for `GRACE_MS`: a dashed strip
    marching along the viewport's top edge and a pill at its bottom counting the time since the loss.
    Once the connection is back, the pill turns to "Back online", holds for `RESTORED_HOLD_MS` and fades out.
    Paints above everything, but lets every pointer event through.
**/
class ConnectionNotice
{
    private static inline final GRACE_MS:Int = 2000;
    private static inline final RESTORED_HOLD_MS:Int = 1000;
    private static inline final ELAPSED_TICK_MS:Int = 1000;
    private static inline final Z_INDEX:String = "100";

    private static var layer:Box;
    private static var strip:DivElement;
    private static var pill:Box;
    private static var content:HBox;
    private static var icon:Image;
    private static var label:Label;
    private static var elapsedLabel:Label;

    private static var lostAt:Null<Float> = null;
    private static var graceTimer:Null<Timer> = null;
    private static var elapsedTimer:Null<Timer> = null;
    private static var restoredTimer:Null<Timer> = null;
    private static var pillTransition:Null<Animation> = null;
    private static var stripMarch:Null<Animation> = null;
    private static var stripFade:Null<Animation> = null;

    /** Must be called once, after `HaxeFolioApp.init` **/
    public static function init():Void
    {
        icon = new Image();
        icon.width = 16;
        icon.height = 16;
        icon.verticalAlign = "center";

        label = new Label();
        label.addClass(StyleClass.CONNECTION_NOTICE_LABEL);
        label.verticalAlign = "center";

        elapsedLabel = new Label();
        elapsedLabel.addClass(StyleClass.CONNECTION_NOTICE_ELAPSED);
        elapsedLabel.verticalAlign = "center";

        content = new HBox();
        content.addClass(StyleClass.CONNECTION_NOTICE_CONTENT);
        content.verticalAlign = "center";
        content.addComponent(icon);
        content.addComponent(label);
        content.addComponent(elapsedLabel);

        pill = new Box();
        pill.addClass(StyleClass.CONNECTION_NOTICE_PILL);
        pill.horizontalAlign = "center";
        pill.verticalAlign = "bottom";
        pill.element.setAttribute("role", "status");
        pill.addComponent(content);

        layer = new Box();
        layer.id = "intellector-connection-notice";
        layer.addClass(StyleClass.CONNECTION_NOTICE_LAYER);
        layer.percentWidth = 100;
        layer.percentHeight = 100;
        layer.hidden = true;
        layer.addComponent(pill);

        Screen.instance.addComponent(layer);
        layer.element.style.zIndex = Z_INDEX;
        layer.element.style.pointerEvents = "none";

        // HaxeUI's styling would wipe a background image set on a component of its own
        strip = Browser.document.createDivElement();
        strip.style.position = "absolute";
        strip.style.left = "0";
        strip.style.top = "0";
        strip.style.width = "100%";
        strip.style.height = '${StyleVars.CONNECTION_NOTICE_STRIP_HEIGHT}px';
        strip.style.backgroundImage = StyleVars.CONNECTION_NOTICE_STRIP_DASHES;
        strip.style.backgroundSize = '${StyleVars.CONNECTION_NOTICE_STRIP_PERIOD}px 100%';
        layer.element.appendChild(strip);
    }

    /** Called whenever the connection closes, and after each failed attempt to open one **/
    public static function onDisconnected():Void
    {
        if (lostAt != null)
            return;

        lostAt = Date.now().getTime();

        if (layer.hidden)
            graceTimer = Timer.delay(showReconnecting, GRACE_MS);
        else
            showReconnecting(); // still saying "Back online"
    }

    public static function onConnected():Void
    {
        if (lostAt == null)
            return;

        lostAt = null;

        if (graceTimer != null)
        {
            graceTimer.stop();
            graceTimer = null;
        }
        else
            showRestored();
    }

    private static function showReconnecting():Void
    {
        graceTimer = null;
        cancelTransitions();

        icon.resource = Assets.connectionIcon("reconnecting");
        label.text = LocaleUtils.localeBinding("intellector.connection_notice.reconnecting");
        elapsedLabel.hidden = false;
        updateElapsed();
        elapsedTimer = new Timer(ELAPSED_TICK_MS);
        elapsedTimer.run = updateElapsed;

        if (stripMarch == null && !prefersReducedMotion())
            stripMarch = strip.animate(
                [{backgroundPosition: "0 0"}, {backgroundPosition: '${StyleVars.CONNECTION_NOTICE_STRIP_PERIOD}px 0'}],
                {duration: StyleVars.CONNECTION_NOTICE_STRIP_PERIOD_MS, iterations: Math.POSITIVE_INFINITY}
            );

        if (layer.hidden)
        {
            layer.hidden = false;
            HaxeFolioApp.setNotificationBottomInset(StyleVars.CONNECTION_NOTICE_NOTIFICATION_INSET);
            pillTransition = slidePill(StyleVars.CONNECTION_NOTICE_ENTER_EXIT_SLIDE, 0, 0, 1, "ease-out");
        }
    }

    // the content fades out and back in as "Back online", while the pill narrows to it
    private static function showRestored():Void
    {
        stopElapsedTimer();

        if (stripMarch != null)
        {
            stripMarch.cancel();
            stripMarch = null;
        }
        stripFade = strip.animate([{opacity: 1}, {opacity: 0}], {duration: StyleVars.CONNECTION_NOTICE_ENTER_EXIT_MS, fill: FORWARDS});

        var fadeOut:Animation = fadeContent(1, 0, "ease-in");
        fadeOut.onfinish = () -> {
            fadeOut.cancel();
            pill.element.style.transition = 'width ${StyleVars.CONNECTION_NOTICE_ENTER_EXIT_MS}ms ease, left ${StyleVars.CONNECTION_NOTICE_ENTER_EXIT_MS}ms ease';
            icon.resource = Assets.connectionIcon("restored");
            label.text = LocaleUtils.localeBinding("intellector.connection_notice.restored");
            elapsedLabel.hidden = true;
            pillTransition = fadeContent(0, 1, "ease-out");
            restoredTimer = Timer.delay(hide, StyleVars.CONNECTION_NOTICE_FADE_MS + RESTORED_HOLD_MS);
        };
        pillTransition = fadeOut;
    }

    private static function hide():Void
    {
        restoredTimer = null;
        pillTransition = slidePill(0, StyleVars.CONNECTION_NOTICE_ENTER_EXIT_SLIDE, 1, 0, "ease-in");
        pillTransition.onfinish = () -> {
            layer.hidden = true;
            cancelTransitions();
            HaxeFolioApp.setNotificationBottomInset(0);
        };
    }

    private static function cancelTransitions():Void
    {
        stopElapsedTimer();

        if (restoredTimer != null)
        {
            restoredTimer.stop();
            restoredTimer = null;
        }

        for (animation in [pillTransition, stripFade])
            if (animation != null)
                animation.cancel();

        pillTransition = null;
        stripFade = null;
        pill.element.style.transition = "";
    }

    private static function stopElapsedTimer():Void
    {
        if (elapsedTimer != null)
        {
            elapsedTimer.stop();
            elapsedTimer = null;
        }
    }

    private static function updateElapsed():Void
    {
        if (lostAt != null)
            elapsedLabel.text = ClockFormatters.formatElapsedTime(Date.now().getTime() - lostAt);
    }

    private static function fadeContent(fromOpacity:Float, toOpacity:Float, easing:String):Animation
    {
        return content.element.animate(
            [{opacity: fromOpacity}, {opacity: toOpacity}],
            {duration: StyleVars.CONNECTION_NOTICE_FADE_MS, easing: easing, fill: fillMode(toOpacity)}
        );
    }

    private static function slidePill(fromShift:Float, toShift:Float, fromOpacity:Float, toOpacity:Float, easing:String):Animation
    {
        return pill.element.animate(
            [{opacity: fromOpacity, transform: 'translateY(${fromShift}px)'}, {opacity: toOpacity, transform: 'translateY(${toShift}px)'}],
            {duration: StyleVars.CONNECTION_NOTICE_ENTER_EXIT_MS, easing: easing, fill: fillMode(toOpacity)}
        );
    }

    // a fade to transparent holds until cancelled; any other ends in the element's own style, so needs no cancelling
    private static function fillMode(toOpacity:Float):FillMode
    {
        return toOpacity == 0 ? FORWARDS : NONE;
    }

    private static function prefersReducedMotion():Bool
    {
        return Browser.window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    }
}
