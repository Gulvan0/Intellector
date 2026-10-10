package client.ui.common.challenges.widget;

import client.datatypes.ChallengeAcceptorColor;
import client.datatypes.IncomingChallenge;
import client.datatypes.OutgoingChallenge;
import client.datatypes.TimeControl;
import client.datatypes.TimeControlKind;
import client.ui.Assets;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import intellectorboard.position.Position;

using client.ui.ComponentExtension;

/** A pending challenge in the challenges widget's list **/
@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/challenges/widget/challenge_entry.xml"))
class ChallengeEntry extends VBox
{
    public final challengeId:Int;
    /** The colour the user plays **/
    public final ownColor:ChallengeAcceptorColor;
    public final customStartingPosition:Null<Position>;
    /** What the preview of its position is titled, in the current language **/
    public final previewTitle:Void->String;

    /** Called with whether the Preview button became selected **/
    public var onPreviewToggled:Bool->Void = _ -> {};

    public static function incoming(challenge:IncomingChallenge, onDecline:Void->Void, onAccept:Void->Void):ChallengeEntry
    {
        var entry:ChallengeEntry = new ChallengeEntry(
            challenge.id,
            challenge.acceptorColor,
            challenge.customStartingPosition,
            () -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.challenges_widget.position_from"), challenge.callerNickname)
        );
        entry.opponentLabel.text = challenge.callerNickname;
        entry.fillFacts(challenge.timeControl, challenge.timeControlKind, challenge.rated);

        entry.declineButton.hidden = false;
        entry.acceptButton.hidden = false;
        entry.declineButton.onClick = _ -> onDecline();
        entry.acceptButton.onClick = _ -> onAccept();
        return entry;
    }

    public static function outgoing(challenge:OutgoingChallenge, onCancel:Void->Void):ChallengeEntry
    {
        var isOpen:Bool = challenge.calleeNickname == null;
        var previewTitle:Void->String = isOpen
            ? () -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.challenges_widget.your_open_challenge"))
            : () -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.challenges_widget.your_challenge_to"), challenge.calleeNickname);
        var entry:ChallengeEntry = new ChallengeEntry(challenge.id, challenge.ownColor, challenge.customStartingPosition, previewTitle);
        entry.opponentLabel.text = isOpen ? LocaleUtils.localeBinding("intellector.challenges_widget.open_challenge") : challenge.calleeNickname;
        entry.opponentLabel.setClass(StyleClass.CHALLENGE_ENTRY_OPPONENT_OPEN, isOpen);
        entry.fillFacts(challenge.timeControl, challenge.timeControlKind, challenge.rated);

        entry.cancelButton.hidden = false;
        entry.cancelButton.onClick = _ -> onCancel();
        return entry;
    }

    private function new(challengeId:Int, ownColor:ChallengeAcceptorColor, customStartingPosition:Null<Position>, previewTitle:Void->String)
    {
        super();

        this.challengeId = challengeId;
        this.ownColor = ownColor;
        this.customStartingPosition = customStartingPosition;
        this.previewTitle = previewTitle;

        previewToggle.onChange = _ -> onPreviewToggled(previewToggle.selected);
    }

    public function setRepliesEnabled(enabled:Bool):Void
    {
        declineButton.disabled = !enabled;
        acceptButton.disabled = !enabled;
    }

    public function setPreviewSelected(selected:Bool):Void
    {
        previewToggle.selected = selected;
    }

    /** Whether it's the first of its section, which has no hairline above it **/
    public function setFirst(first:Bool):Void
    {
        this.setClass(StyleClass.CHALLENGE_ENTRY_FIRST, first);
    }

    /** Briefly highlights the entry as a new arrival **/
    public function highlightArrival():Void
    {
        addClass(StyleClass.CHALLENGE_ENTRY_ARRIVED);
        onAnimationEnd = _ -> removeClass(StyleClass.CHALLENGE_ENTRY_ARRIVED);
    }

    private function fillFacts(timeControl:TimeControl, timeControlKind:TimeControlKind, rated:Bool):Void
    {
        var isCustomPosition:Bool = customStartingPosition != null;

        timeControlTag.setTimeControl(timeControl, timeControlKind);
        colorIcon.resource = Assets.colorIcon(ownColor.getColor());
        colorLabel.text = GroupedLocaleResolvers.acceptorColor(ownColor);
        ratedLabel.text = GroupedLocaleResolvers.challengeRated(rated);
        positionLabel.text = GroupedLocaleResolvers.positionFact(isCustomPosition);

        ratedLabel.setClass(StyleClass.CHALLENGE_ENTRY_FACT_EMPHASISED, rated);
        positionLabel.setClass(StyleClass.CHALLENGE_ENTRY_FACT_EMPHASISED, isCustomPosition);
        previewToggle.hidden = !isCustomPosition;
    }
}
