package client.ui.common.notifications.challenges;

import client.datatypes.IncomingChallenge;
import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import haxefolio.ElementShadow;
import js.html.KeyframeAnimationOptions;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/notifications/challenge_compact_row.xml"))
class ChallengeCompactRow extends HBox
{
    public final challenge:IncomingChallenge;

    public function new(challenge:IncomingChallenge, collapsed:Bool, onPress:Void->Void)
    {
        super();

        this.challenge = challenge;

        if (collapsed)
            addClass(StyleClass.CHALLENGE_ROW_COLLAPSED);
        element.style.cursor = "pointer";
        ElementShadow.apply(element, StyleVars.CHALLENGE_ROW_SHADOW);

        nickname.text = challenge.callerNickname;
        timeControlTag.setTimeControl(challenge.timeControl, challenge.timeControlKind);

        // inherited by the subtree, so the row is always the event target
        for (child in childComponents)
            child.element.style.pointerEvents = "none";

        registerEvent(MouseEvent.MOUSE_OVER, _ -> addClass(StyleClass.CHALLENGE_ROW_HOVER));
        registerEvent(MouseEvent.MOUSE_OUT, _ -> removeClass(StyleClass.CHALLENGE_ROW_HOVER));
        registerEvent(MouseEvent.CLICK, _ -> onPress());
    }

    /** Shows "+`count`" challenges waiting without a row; hidden for 0 **/
    public function setHiddenCount(count:Int):Void
    {
        countPill.hidden = count == 0;
        countPill.text = '+$count';
    }

    /** Briefly highlights the row as a new arrival **/
    public function highlightArrival():Void
    {
        var highlightedState:Dynamic = {
            backgroundColor: StyleVars.CHALLENGE_ROW_HIGHLIGHT_FILL,
            borderColor: StyleVars.CHALLENGE_ROW_HIGHLIGHT_BORDER
        };
        var options:KeyframeAnimationOptions = {
            delay: StyleVars.CHALLENGE_ROW_HIGHLIGHT_HOLD_MS,
            duration: StyleVars.CHALLENGE_ROW_HIGHLIGHT_FADE_MS,
            fill: BACKWARDS  // Apply highlighted state => Wait => Fade out to normal stylesheet colours
        };

        element.animate([highlightedState], options);
    }
}
