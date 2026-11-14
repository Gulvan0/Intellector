package net.rest;

import haxe.io.Bytes;
import http.HttpError;
import js.Browser;
import js.html.Blob;
import js.html.Headers;
import js.html.Response;
import js.lib.ArrayBuffer;
import jsonmodel.JsonSerializable;

/** Requests answered with a file rather than JSON, which `RestClient` can't take **/
class FileRequests
{
    private static final FILE_NAME_PATTERN:EReg = ~/filename="?([^";]+)"?/;

    /**
        POSTs `body` to `path` (relative to the API's base URL). `onFile` gets the file and its name,
        from the response's `Content-Disposition` if readable, else `fallbackName`. `onError` gets
        an error carrying the status and the body, as the REST client's would.
    **/
    public static function post(path:String, body:JsonSerializable, fallbackName:String, onFile:(Blob, String)->Void, onError:HttpError->Void):Void
    {
        var headers:Headers = new Headers();
        headers.set("Content-Type", "application/json");
        var token:Null<String> = Rest.token();
        if (token != null)
            headers.set("intellector-user-token", token);

        Browser.window.fetch(Config.BASE_URL + path, {method: "POST", headers: headers, body: body.serialize()}).then(response -> {
            if (response.ok)
                response.blob().then(blob -> onFile(blob, fileNameOf(response) ?? fallbackName), error -> onError(new HttpError(Std.string(error))));
            else
                response.arrayBuffer().then(buffer -> onError(errorOf(response, buffer)), _ -> onError(new HttpError(response.statusText, response.status)));
        }, error -> onError(new HttpError(Std.string(error))));
    }

    private static function fileNameOf(response:Response):Null<String>
    {
        var disposition:Null<String> = response.headers.get("Content-Disposition");
        return disposition != null && FILE_NAME_PATTERN.match(disposition) ? FILE_NAME_PATTERN.matched(1) : null;
    }

    private static function errorOf(response:Response, buffer:ArrayBuffer):HttpError
    {
        var error:HttpError = new HttpError(response.statusText, response.status);
        error.body = Bytes.ofData(buffer);
        return error;
    }
}
