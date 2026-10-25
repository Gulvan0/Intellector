package client.ui.common.account;

import client.auth.Identity;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;

using client.ui.ComponentExtension;

/**
    The account widget's icon, a disc: an ink one with the nickname's initial for a player, a muted
    one with the guest's number (its last 3 digits past 999) for a guest, or with "?" while the
    guest's number is unknown.
**/
class AccountIcon extends Box
{
    private static inline final SIZE:Float = 24;
    private static inline final GUEST_DIGITS:Int = 3;

    private final disc:Box;
    private final caption:Label;

    public function new()
    {
        super();

        width = SIZE;
        height = SIZE;

        disc = new Box();
        disc.addClass(StyleClass.ACCOUNT_ICON_DISC);
        addComponent(disc);

        caption = new Label();
        caption.addClass(StyleClass.ACCOUNT_ICON_CAPTION);
        caption.horizontalAlign = "center";
        caption.verticalAlign = "center";
        disc.addComponent(caption);

        setIdentity(Guest(null));
    }

    public function setIdentity(identity:Identity):Void
    {
        var text:String = switch identity {
            case Player(_, nickname): nickname.charAt(0).toUpperCase();
            case Guest(guestId): guestId != null ? Std.string(guestId).substr(-GUEST_DIGITS) : "?";
        }

        caption.text = text;

        disc.setClass(StyleClass.ACCOUNT_ICON_DISC_GUEST, identity.isGuest());
        caption.setClass(StyleClass.ACCOUNT_ICON_CAPTION_GUEST, identity.isGuest());
        caption.setClass(StyleClass.ACCOUNT_ICON_CAPTION_SMALL, text.length == GUEST_DIGITS);
    }
}
