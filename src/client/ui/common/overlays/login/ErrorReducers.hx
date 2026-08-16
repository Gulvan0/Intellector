package client.ui.common.overlays.login;

import http.HttpError;

class ErrorReducers
{
    private static inline final GENERIC_ERROR_SLUG = "response.generic_error";

    private static final INVALID_CREDS_RESPONSE_CODES = [401, 404];  // collapsed into one generic message on purpose

    public static function signInErrorSlug(error:HttpError):String
    {
        if (INVALID_CREDS_RESPONSE_CODES.contains(error.httpStatus))
            return "response.invalid_credentials";

        return GENERIC_ERROR_SLUG;
    }

    public static function registerErrorSlug(error:HttpError):String
    {
        if (isLoginTakenError(error))
            return "response.login_taken";

        return GENERIC_ERROR_SLUG;
    }

    private static function isLoginTakenError(error:HttpError):Bool
    {
        if (error.body == null)
            return false;

        try
            return Reflect.field(error.bodyAsJson, "detail") == "User already exists"
        catch (_:Dynamic)
            return false;
    }
}
