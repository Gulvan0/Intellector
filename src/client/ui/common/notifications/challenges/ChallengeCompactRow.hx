package client.ui.common.notifications.challenges;

import client.datatypes.IncomingChallenge;
import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import haxefolio.ElementShadow;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/notifications/challenge_compact_row.xml"))
class ChallengeCompactRow extends HBox
{
    public final challenge:IncomingChallenge;

    public function new(challenge:IncomingChallenge, onPress:Void->Void)
    {
        super();

        this.challenge = challenge;

        ElementShadow.apply(element, StyleVars.CHALLENGE_ROW_SHADOW);

        nickname.text = challenge.callerNickname;
        timeControlTag.setTimeControl(challenge.timeControl, challenge.timeControlKind);

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
        addClass(StyleClass.CHALLENGE_ROW_ARRIVED);
        onAnimationEnd = _ -> removeClass(StyleClass.CHALLENGE_ROW_ARRIVED);
    }
}
