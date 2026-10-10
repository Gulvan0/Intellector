package client.ui.common.notifications.challenges;

import client.datatypes.IncomingChallenge;
import client.ui.Assets;
import client.ui.common.challenges.PositionPreviewPopover;
import haxefolio.AnchorPlacement;
import haxefolio.Anchoring;
import haxefolio.ByWidth;
import haxefolio.notification.NotificationCard;
import intellectorboard.primitives.piece.PieceColor;
import morestd.Detachable;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/notifications/challenge_card.xml"))
class ChallengeCard extends NotificationCard
{
    public final challenge:IncomingChallenge;

    private var preview:Null<PositionPreviewPopover> = null;
    private var previewAnchoring:Null<Detachable> = null;

    public function new(challenge:IncomingChallenge, onClose:Void->Void, onDecline:Void->Void, onAccept:Void->Void, onPreviewOpened:Void->Void)
    {
        super();

        this.challenge = challenge;

        // clips the cells' square corners to the grid's rounded ones, which HaxeUI's clip: true doesn't
        facts.element.style.overflow = "hidden";

        title = challenge.callerNickname;
        this.onClose = onClose;
        timeControlTag.setTimeControl(challenge.timeControl, challenge.timeControlKind);

        var isCustomPosition:Bool = challenge.customStartingPosition != null;

        ratedLabel.text = GroupedLocaleResolvers.challengeRated(challenge.rated);
        sideLabel.text = GroupedLocaleResolvers.acceptorColor(challenge.acceptorColor);
        positionLabel.text = GroupedLocaleResolvers.positionType(isCustomPosition);

        if (challenge.rated)
            ratedLabel.addClass(StyleClass.CHALLENGE_FACT_VALUE_EMPHASISED);
        if (isCustomPosition)
            positionLabel.addClass(StyleClass.CHALLENGE_FACT_VALUE_EMPHASISED);

        sideIcon.resource = Assets.colorIcon(challenge.acceptorColor.getColor());

        previewToggle.hidden = !isCustomPosition;
        previewToggle.onChange = _ -> {
            updatePreview();
            if (previewToggle.selected)
                onPreviewOpened();
        };

        declineButton.onClick = _ -> onDecline();
        acceptButton.onClick = _ -> onAccept();
    }

    public function setRepliesEnabled(enabled:Bool):Void
    {
        declineButton.enabled = enabled;
        acceptButton.enabled = enabled;
    }

    public function closePreview():Void
    {
        previewToggle.selected = false;
    }

    private override function onDestroy():Void
    {
        if (previewAnchoring != null)
            previewAnchoring.detach();
        super.onDestroy();
    }

    // shown while the toggle is selected
    private function updatePreview():Void
    {
        if (preview == null)
        {
            if (!previewToggle.selected)
                return;

            preview = new PositionPreviewPopover(challenge.customStartingPosition, challenge.acceptorColor.getColor() ?? White);
            attach(preview);

            var expanded:AnchorPlacement = {side: Left, align: End};
            var collapsed:AnchorPlacement = {side: Above, align: Start, stretch: true};
            var placement:ByWidth<AnchorPlacement> = {expanded: expanded, collapsed: collapsed};
            previewAnchoring = Anchoring.attach(preview, this, placement);
        }

        preview.hidden = !previewToggle.selected;
    }
}
