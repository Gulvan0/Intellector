package client.ui.common.challenges.widget;

import client.datatypes.challenge.ChallengeAcceptorColor;
import client.datatypes.challenge.IncomingChallenge;
import client.datatypes.challenge.OutgoingChallenge;
import client.datatypes.timecontrol.TimeControl;
import client.datatypes.timecontrol.TimeControlKind;
import client.ui.Assets;
import client.ui.common.SeparatedFlow;
import client.ui.common.notifications.InfoNotice;
import client.utils.PagePaths;
import haxe.Timer;
import haxe.ui.containers.VBox;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.browser.Clipboard;
import intellectorboard.position.Position;

using client.ui.ComponentExtension;

/** A pending challenge in the challenges widget's list **/
@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/challenges/widget/challenge_entry.xml"))
class ChallengeEntry extends VBox
{
    private static inline final COPIED_MS:Int = 1600;
    private static inline final COPY_FAILED_NOTICE_MS:Int = 6000;

    public final challengeId:Int;
    /** The colour the user plays **/
    public final ownColor:ChallengeAcceptorColor;
    public final customStartingPosition:Null<Position>;
    /** What the preview of its position is titled, in the current language **/
    public final previewTitle:Void->String;

    /** Called with whether the Preview button became selected **/
    public var onPreviewToggled:Bool->Void = _ -> {};

    private var copiedResetTimer:Null<Timer> = null;

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

        entry.copyLinkButton.hidden = false;
        entry.copyLinkButton.onClick = _ -> entry.copyLink();
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
        new SeparatedFlow(factFlow, [colorPart, ratedLabel, positionLabel], StyleClass.CHALLENGE_ENTRY_FACT_GROUP, StyleClass.CHALLENGE_ENTRY_SEPARATOR);
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

    private override function onDestroy():Void
    {
        stopCopiedResetTimer();
        super.onDestroy();
    }

    private function copyLink():Void
    {
        var url:String = HaxeFolioApp.pageUrl(PagePaths.challenge(challengeId));

        // without a secure origin there is no `navigator.clipboard` at all
        try
        {
            Clipboard.copy(url, onLinkCopied, _ -> onCopyFailed());
        }
        catch (_)
        {
            onCopyFailed();
        }
    }

    // the button keeps its width while it reads "Copied", so the row doesn't shift
    private function onLinkCopied():Void
    {
        if (copiedResetTimer == null)
            copyLinkButton.width = copyLinkButton.componentWidth;
        stopCopiedResetTimer();

        copyLinkButton.text = LocaleUtils.localeBinding("intellector.challenges_widget.copied");
        copiedResetTimer = Timer.delay(() -> {
            copiedResetTimer = null;
            copyLinkButton.text = LocaleUtils.localeBinding("intellector.challenges_widget.copy_link");
            copyLinkButton.width = null;
            copyLinkButton.invalidateComponentLayout();
        }, COPIED_MS);
    }

    private function onCopyFailed():Void
    {
        InfoNotice.show("intellector.common.copy.error_title", "intellector.challenges_widget.copy_failed", COPY_FAILED_NOTICE_MS);
    }

    private function stopCopiedResetTimer():Void
    {
        if (copiedResetTimer != null)
            copiedResetTimer.stop();
        copiedResetTimer = null;
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
