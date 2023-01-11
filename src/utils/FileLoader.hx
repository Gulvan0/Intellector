package utils;

import js.html.XMLHttpRequest;

class FileLoader 
{
    public static function loadText(path:String, callback:String->Void) 
    {
        var req = new XMLHttpRequest();
        req.onload = () -> {
            callback(req.responseText);
        };
        req.open('GET', path, false);
        req.send();
    }
}