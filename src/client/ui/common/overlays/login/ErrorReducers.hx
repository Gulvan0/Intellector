package client.ui.common.overlays.login;

import http.HttpError;
import net.rest.RestErrors;

class ErrorReducers
{
    private static inline final GENERIC_ERROR_SLUG = "response.generic_error";

    public static function signInErrorSlug(error:HttpError):String
    {
        return switch RestErrors.codeOf(error) {
            case USER_NOT_FOUND | INVALID_CREDENTIALS: "response.invalid_credentials"; // collapsed into one message on purpose
            default: GENERIC_ERROR_SLUG;
        }
    }

    public static function registerErrorSlug(error:HttpError):String
    {
        return switch RestErrors.codeOf(error) {
            case USER_ALREADY_EXISTS: "response.login_taken";
            default: GENERIC_ERROR_SLUG;
        }
    }
}
