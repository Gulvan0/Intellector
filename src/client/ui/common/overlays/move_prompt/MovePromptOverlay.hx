package client.ui.common.overlays.move_prompt;

import client.Assets;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.overlay.OverlayContent;
import haxefolio.structure.ActionBar;
import haxefolio.structure.ActionButton;
import intellectorboard.movement.rules.CoreRules;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceKind;

/**
    The two move-detail choices `MoveInteractionController` can't resolve on its own: which piece
    a Progressor promotes into, and whether a chameleon-eligible capture morphs. Replaces the old
    `PromotionSelect`/`Dialogs.confirm` popups per CLAUDE.md's dialog-replacement rule. Deliberately
    minimal for this pass (knowledge/plans/board_deferred.md item 1) - no keyboard-modifier
    shortcuts to skip the prompt, unlike the old dialogs.
**/
class MovePromptOverlay
{
    private static inline final ICON_SIZE:Int = 72;

    public static function presentPromotion(color:PieceColor, onChosen:PieceKind->Void):Void
    {
        HaxeFolioApp.present("promotion", dismiss -> build(color, dismiss, onChosen));
    }

    public static function presentChameleon(onDecision:Bool->Void):Void
    {
        HaxeFolioApp.present("chameleon", dismiss -> buildChameleonPrompt(dismiss, onDecision));
    }

    private static function build(color:PieceColor, dismiss:Void->Void, onChosen:PieceKind->Void):OverlayContent
    {
        var options:HBox = new HBox();
        options.percentWidth = 100;
        options.horizontalAlign = "center";

        for (kind in CoreRules.POSSIBLE_PROMOTION_OPTIONS)
        {
            var button:Button = new Button();
            button.icon = Assets.pieceImage(kind, color);
            button.width = ICON_SIZE;
            button.height = ICON_SIZE;
            button.onClick = _ -> {
                dismiss();
                onChosen(kind);
            };
            options.addComponent(button);
        }

        return {
            regions: [
                Header(LocaleUtils.localeBinding("intellector.overlay.promotion.title")),
                Custom(ICON_SIZE + 40, options)
            ]
        };
    }

    private static function buildChameleonPrompt(dismiss:Void->Void, onDecision:Bool->Void):OverlayContent
    {
        var question:Label = new Label();
        question.text = LocaleUtils.resolveText("intellector.overlay.chameleon.question");
        question.percentWidth = 100;
        question.horizontalAlign = "center";

        function decide(chameleon:Bool):Void
        {
            dismiss();
            onDecision(chameleon);
        }

        var noButton:ActionButton = new ActionButton(LocaleUtils.resolveText("intellector.overlay.chameleon.no"), () -> decide(false));
        var yesButton:ActionButton = new ActionButton(LocaleUtils.resolveText("intellector.overlay.chameleon.yes"), () -> decide(true), true);

        return {
            regions: [
                Header(LocaleUtils.localeBinding("intellector.overlay.chameleon.title")),
                Custom(60, question),
                Actions(new ActionBar([noButton, yesButton]))
            ]
        };
    }
}
