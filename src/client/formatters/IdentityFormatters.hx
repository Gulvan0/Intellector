package client.formatters;

import haxefolio.LocaleUtils;
import client.auth.Identity;

class IdentityFormatters
{
    public static function formatRaw(identity:Identity):String
    {
        switch identity
        {
            case Player(_, nickname):
                return nickname;
            case Guest(guestId):
                if (guestId != null)
                    return LocaleUtils.localeBinding("intellector.common.player.guest_name", Std.string(guestId));
                else
                    return LocaleUtils.localeBinding("intellector.common.player.guest_generic");
        }
    }

    public static function formatResolved(identity:Identity):String
    {
        return LocaleUtils.resolveText(formatRaw(identity));
    }
}
