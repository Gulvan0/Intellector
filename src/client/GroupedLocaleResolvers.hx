package client;

import haxefolio.LocaleUtils;

class GroupedLocaleResolvers
{
    public static function loginOverlayError(errorSlug:String):String
    {
        return LocaleUtils.localeBinding('intellector.overlay.login.error.$errorSlug');
    }
}
