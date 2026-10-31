package client.ui.common.overlays.challenge.bot;

import client.GroupedLocaleResolvers.challengeOverlay as phrase;
import client.datatypes.bot.BotKind;
import client.logic.bot.BotKinds;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.overlay.OverlayContent;
import haxefolio.structure.ActionButton;

/** What a bot is like, over the challenge creation overlay **/
class BotAboutOverlay
{
    public static function present(kind:BotKind):Void
    {
        HaxeFolioApp.presentOver("bot_about", build.bind(kind), null, {
            geometry: {
                dialogWidth: StyleVars.BOT_ABOUT_OVERLAY_WIDTH,
                dialogHeight: StyleVars.BOT_ABOUT_OVERLAY_HEIGHT,
                headerHeight: StyleVars.BOT_ABOUT_OVERLAY_HEADER_HEIGHT
            }
        });
    }

    private static function build(kind:BotKind, dismiss:Void->Void):OverlayContent
    {
        var description:Label = new Label();
        description.text = LocaleUtils.localeBinding(BotKinds.descriptionLocaleKey(kind));
        description.percentWidth = 100;
        description.wordWrap = true;
        description.addClass(StyleClass.CHALLENGE_BOT_ABOUT_TEXT);

        var footer:Box = new Box();
        footer.percentWidth = 100;
        footer.percentHeight = 100;
        footer.addClass(StyleClass.CHALLENGE_BOT_ABOUT_FOOTER);

        var closeButton:ActionButton = new ActionButton(phrase("bot.close"), dismiss);
        closeButton.verticalAlign = "center";
        closeButton.horizontalAlign = "right";
        footer.addComponent(closeButton);

        return {
            regions: [
                Header(BotKinds.displayName(kind)),
                Scroll(description),
                Custom(StyleVars.BOT_ABOUT_OVERLAY_FOOTER_HEIGHT, footer)
            ]
        };
    }
}
