package client;

import intellectorboard.primitives.piece.PieceColor;
import client.datatypes.ChallengeAcceptorColor;
import haxefolio.LocaleUtils;

class GroupedLocaleResolvers
{
    public static function loginOverlayError(errorSlug:String):String
    {
        return LocaleUtils.localeBinding('intellector.overlay.login.error.$errorSlug');
    }

    public static function acceptorColor(acceptorColor:ChallengeAcceptorColor):String
    {
        return LocaleUtils.localeBinding('intellector.challenge_notification.acceptor_color.${acceptorColor.getName().toLowerCase()}');
    }

    public static function challengeRated(rated:Bool):String
    {
        var key:String = rated ? "rated" : "unrated";
        return LocaleUtils.localeBinding('intellector.challenge_notification.$key');
    }

    public static function positionType(custom:Bool):String
    {
        var key:String = custom ? "custom" : "default";
        return LocaleUtils.localeBinding('intellector.challenge_notification.position.$key');
    }

    public static function turnColor(color:PieceColor):String
    {
        return LocaleUtils.localeBinding('intellector.common.turn_color.${color.getName().toLowerCase()}');
    }
}
