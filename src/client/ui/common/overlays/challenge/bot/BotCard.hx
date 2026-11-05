package client.ui.common.overlays.challenge.bot;

import client.datatypes.bot.BotKind;
import client.logic.bot.BotKinds;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxefolio.ResponsivityController;
import morestd.Detachable;

/**
    A square card picking a bot: its avatar over its name. A name too long for one line wraps, and
    the avatar shrinks to keep the card square.
**/
class BotCard extends VBox
{
    private final sizeBinding:Detachable;

    public function new(kind:BotKind, onPick:BotKind->Void)
    {
        super();

        this.addClass(StyleClass.CHALLENGE_BOT_CARD);
        ComponentExtension.trackHover(this);

        var avatar:Image = new Image();
        avatar.resource = BotKinds.avatarPath(kind);
        avatar.percentWidth = 100;
        avatar.percentHeight = 100;
        avatar.scaleMode = FIT_INSIDE;
        avatar.imageVerticalAlign = BOTTOM;
        avatar.addClass(StyleClass.CHALLENGE_BOT_CARD_AVATAR);
        this.addComponent(avatar);

        var name:Label = new Label();
        name.text = BotKinds.displayName(kind);
        name.percentWidth = 100;
        name.wordWrap = true;
        name.addClass(StyleClass.CHALLENGE_BOT_CARD_NAME);
        this.addComponent(name);

        this.onClick = _ -> onPick(kind);

        sizeBinding = ResponsivityController.bind(StyleVars.CHALLENGE_OVERLAY_BOT_CARD_SIZE, size -> {
            this.width = size;
            this.height = size;
        });
    }

    public function dispose():Void
    {
        sizeBinding.detach();
    }
}
