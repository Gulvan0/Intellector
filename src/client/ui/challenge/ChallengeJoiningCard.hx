package client.ui.challenge;

import client.datatypes.challenge.ChallengeAcceptorColor;
import client.datatypes.challenge.ChallengeDetails;
import client.datatypes.challenge.ChallengeViewer;
import client.formatters.GameFormatters;
import client.logic.challenge.ChallengeViewers;
import client.ui.Assets;
import client.ui.common.board.BoardPreview;
import haxe.ui.containers.VBox;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import intellectorboard.primitives.piece.PieceColor;

using client.ui.ComponentExtension;

/** A pending challenge with the viewer's action on it: Accept (and Decline, for the callee of a direct one), or Cancel for its owner **/
@:build(haxe.ui.ComponentBuilder.build("assets/layouts/challenge/challenge_joining_card.xml"))
class ChallengeJoiningCard extends VBox
{
    private static inline final PREVIEW_BOARD_WIDTH:Float = 238;

    private final challenge:ChallengeDetails;

    private var viewer:ChallengeViewer = Bystander;
    private var busy:Bool = false;
    private var preview:Null<BoardPreview> = null;
    private var previewOrientation:Null<PieceColor> = null;

    /** Fill in the viewer with `setViewer` **/
    public function new(challenge:ChallengeDetails, onAccept:Void->Void, onDecline:Void->Void, onCancel:Void->Void)
    {
        super();

        this.challenge = challenge;

        headingLabel.text = LocaleUtils.localeBinding(challenge.isDirect() ? "intellector.challenge_joining.direct" : "intellector.challenge_joining.open");
        ownerLabel.text = challenge.callerNickname;

        if (challenge.rated && challenge.callerRating != null)
        {
            ratingLabel.text = GameFormatters.bareRating(challenge.callerRating);
            ratingLabel.hidden = false;
        }

        if (challenge.calleeNickname != null)
        {
            LocaleManager.instance.registerComponent(calleeLabel, "text", resolveCalleeText); // a binding would parse the nickname as an expression
            calleeLabel.hidden = false;
        }

        timeControlTag.setTimeControl(challenge.timeControl, challenge.timeControlKind);
        kindLabel.text = LocaleUtils.localeBinding('intellector.common.time_control_kind.${challenge.timeControlKind.getName().toLowerCase()}');
        kindLabel.hidden = challenge.timeControlKind == Correspondence; // its time control already reads as the word

        ratedLabel.text = LocaleUtils.localeBinding(challenge.rated ? "intellector.common.game_type.rated" : "intellector.common.game_type.casual");
        positionLabel.text = GroupedLocaleResolvers.positionType(challenge.customStartingPosition != null);
        previewFrame.hidden = challenge.customStartingPosition == null;

        actionButton.onClick = _ -> {
            if (viewer == Owner)
                onCancel();
            else
                onAccept();
        };
        declineButton.onClick = _ -> onDecline();
    }

    /** Fills in what depends on who is looking: their colour, the board's orientation and the action **/
    public function setViewer(viewer:ChallengeViewer):Void
    {
        this.viewer = viewer;

        var color:ChallengeAcceptorColor = ChallengeViewers.colorOf(viewer, challenge);
        colorIcon.resource = Assets.colorIcon(color.getColor());
        colorLabel.text = GroupedLocaleResolvers.acceptorColor(color);

        actionButton.text = LocaleUtils.localeBinding(viewer == Owner ? "intellector.challenge_joining.cancel" : "intellector.challenge_joining.accept");
        actionButton.setClass(StyleClass.JOIN_ACTION_CANCEL, viewer == Owner);
        declineButton.hidden = viewer != Acceptor || !challenge.isDirect();
        refreshActionEnabled();

        updatePreview(color.getColor() ?? White);
    }

    /** Disables the action while its request is in flight **/
    public function setBusy(busy:Bool):Void
    {
        this.busy = busy;
        refreshActionEnabled();
    }

    private function refreshActionEnabled():Void
    {
        actionButton.disabled = busy || viewer == Bystander;
        declineButton.disabled = busy;
    }

    private function updatePreview(orientation:PieceColor):Void
    {
        if (challenge.customStartingPosition == null || orientation == previewOrientation)
            return;

        if (preview != null)
            previewFrame.removeComponent(preview, true);

        previewOrientation = orientation;
        preview = new BoardPreview(challenge.customStartingPosition, orientation, PREVIEW_BOARD_WIDTH);
        preview.horizontalAlign = "center";
        previewFrame.addComponent(preview);
    }

    private function resolveCalleeText():String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.challenge_joining.to"), challenge.calleeNickname);
    }
}
