package utils;

import js.html.RequestCache;
import js.html.RequestInit;
import js.Browser;

class FileLoader 
{
    public static function loadText(path:String, callback:String->Void) 
    {
        var init:RequestInit = {cache: RequestCache.NO_STORE};
        Browser.window.fetch(path, init).then(p -> {
            p.text().then(callback);
        });
    }
}