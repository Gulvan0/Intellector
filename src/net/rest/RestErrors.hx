package net.rest;

import http.HttpError;
import net.models.common.RestErrorCode;
import net.models.common.RestErrorResponse;

class RestErrors
{
    /** The coded body of `error`; null for errors without one (connection failures, uncoded server errors) **/
    public static function responseOf(error:HttpError):Null<RestErrorResponse>
    {
        if (error.body == null)
            return null;

        try
            return new RestErrorResponse(Str(error.bodyAsString))
        catch (_:Dynamic)
            return null;
    }

    public static function codeOf(error:HttpError):Null<RestErrorCode>
    {
        return responseOf(error)?.code;
    }
}
