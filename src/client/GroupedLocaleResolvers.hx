package client;

import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceKind;
import client.datatypes.challenge.ChallengeAcceptorColor;
import client.datatypes.request.FailedAction;
import client.datatypes.request.RequestFailureReason;
import client.datatypes.TabBlinkReason;
import client.ui.common.overlays.login.LoginFormField;
import haxefolio.LocaleUtils;

class GroupedLocaleResolvers
{
    public static function loginOverlayError(errorSlug:String):String
    {
        return LocaleUtils.localeBinding('intellector.overlay.login.error.$errorSlug');
    }

    public static function loginOverlayField(field:LoginFormField):String
    {
        return LocaleUtils.localeBinding('intellector.overlay.login.field.${field.slug()}');
    }

    public static function loginOverlayHint(field:LoginFormField):String
    {
        return LocaleUtils.localeBinding('intellector.overlay.login.hint.${field.slug()}');
    }

    public static function loginOverlayTab(isSignUp:Bool):String
    {
        var key:String = isSignUp ? "register" : "sign_in";
        return LocaleUtils.localeBinding('intellector.overlay.login.tab.$key');
    }

    public static function loginOverlaySubmit(isSignUp:Bool):String
    {
        var key:String = isSignUp ? "register" : "sign_in";
        return LocaleUtils.localeBinding('intellector.overlay.login.submit.$key');
    }

    public static function loginOverlayInFlight(isSignUp:Bool):String
    {
        var key:String = isSignUp ? "register" : "sign_in";
        return LocaleUtils.localeBinding('intellector.overlay.login.in_flight.$key');
    }

    public static function challengeOverlay(key:String):String
    {
        return LocaleUtils.localeBinding('intellector.overlay.challenge.$key');
    }

    public static function importPositionOverlay(key:String):String
    {
        return LocaleUtils.localeBinding('intellector.overlay.import_position.$key');
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

    public static function positionFact(custom:Bool):String
    {
        var key:String = custom ? "custom" : "default";
        return LocaleUtils.localeBinding('intellector.challenges_widget.position.$key');
    }

    public static function turnColor(color:PieceColor):String
    {
        return LocaleUtils.localeBinding('intellector.common.turn_color.${color.getName().toLowerCase()}');
    }

    public static function pieceName(kind:PieceKind, grammaticalCase:String):String
    {
        return LocaleUtils.localeBinding('intellector.piece.${kind.getName().toLowerCase()}.$grammaticalCase');
    }

    public static function analysisTitle(isStudy:Bool):String
    {
        var key:String = isStudy ? "study_title" : "title";
        return LocaleUtils.localeBinding('intellector.analysis.$key');
    }

    public static function browserTabTitle(reason:TabBlinkReason):String
    {
        return switch reason {
            case IncomingChallenge: LocaleUtils.localeBinding("intellector.browser_tab.new_challenge");
            case GameStarted: LocaleUtils.localeBinding("intellector.browser_tab.game_started");
        }
    }

    public static function requestFailureTitle(action:FailedAction):String
    {
        return LocaleUtils.localeBinding('intellector.request_failure.title.$action');
    }

    public static function requestFailureReason(reason:RequestFailureReason):String
    {
        return switch reason {
            case NoConnection: LocaleUtils.localeBinding("intellector.request_failure.reason.no_connection");
            case ServerError(httpStatus): LocaleUtils.localeBinding("intellector.request_failure.reason.server_error", Std.string(httpStatus));
            case Unexpected: LocaleUtils.localeBinding("intellector.request_failure.reason.unexpected");
            case ChallengeUnavailable: LocaleUtils.localeBinding("intellector.request_failure.reason.challenge_unavailable");
            case ChallengeAlreadyExists: LocaleUtils.localeBinding("intellector.request_failure.reason.challenge_already_exists");
            case TooManyActiveChallenges(maxActiveChallenges): LocaleUtils.localeBinding("intellector.request_failure.reason.too_many_active_challenges", Std.string(maxActiveChallenges));
            case TooManyDirectChallenges(maxActiveChallenges): LocaleUtils.localeBinding("intellector.request_failure.reason.too_many_direct_challenges", Std.string(maxActiveChallenges));
            case ServerRestarting: LocaleUtils.localeBinding("intellector.request_failure.reason.server_restarting");
        }
    }
}
