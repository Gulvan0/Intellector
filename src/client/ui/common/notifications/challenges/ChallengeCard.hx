package client.ui.common.notifications.challenges;

import client.datatypes.IncomingChallenge;
import client.ui.Assets;
import haxe.ui.components.Label;
import haxefolio.notification.NotificationCard;

using client.ui.ComponentExtension;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/notifications/challenge_card.xml"))
class ChallengeCard extends NotificationCard
{
    public final challenge:IncomingChallenge;

    private final collapsed:Bool;
    private final previewToggle:Null<PreviewToggle>;

    private var preview:Null<PositionPreviewPopover> = null;

    public function new(challenge:IncomingChallenge, collapsed:Bool, onClose:Void->Void, onDecline:Void->Void, onAccept:Void->Void)
    {
        super();

        this.challenge = challenge;
        this.collapsed = collapsed;

        // clips the cells' square corners to the grid's rounded ones
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

        if (isCustomPosition)
        {
            previewToggle = new PreviewToggle(togglePreview);
            previewToggle.verticalAlign = "center";
            positionLabel.percentWidth = 100;
            positionValue.addComponent(previewToggle);
        }
        else
            previewToggle = null;

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
        if (preview == null)
            return;

        detach(preview);
        preview = null;
        previewToggle.setClass(StyleClass.CHALLENGE_PREVIEW_TOGGLE_SELECTED, false);
    }

    private function togglePreview():Void
    {
        if (preview != null)
        {
            closePreview();
            return;
        }

        preview = new PositionPreviewPopover(challenge.customStartingPosition, challenge.acceptorColor);

        // an attached component isn't sized by the card's layout
        if (collapsed)
            preview.width = width;

        attach(preview);

        // measured now to be placed by its real size; safe, as the card is already laid out
        preview.validateNow();

        if (collapsed)
        {
            preview.left = 0;
            preview.top = -(preview.height + StyleVars.CHALLENGE_PREVIEW_GAP_COLLAPSED);
        }
        else
        {
            preview.left = -(preview.width + StyleVars.CHALLENGE_PREVIEW_GAP_EXPANDED);
            preview.top = height - preview.height;
        }

        previewToggle.setClass(StyleClass.CHALLENGE_PREVIEW_TOGGLE_SELECTED, true);
    }
}
