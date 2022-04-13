package url;

import js.Browser;

class URLEditor 
{
    public static function clear() 
    {
        setPath("");
    }

    public static function setPath(path:String, ?title:String)
    {
        if (StringTools.startsWith(path, "/"))
            path = path.substr(1);
        var fullTitle:String = title != null? title + " - Intellector" : "Intellector";
        Browser.window.history.pushState({}, fullTitle, ingameToUrlPath(path));
    }

    public static function getChallengeLink(login:String):String
    {
        return Browser.location.host + ingameToUrlPath('challenge/$login');
    }

    public static function getGameLink(id:String):String
    {
        return Browser.location.host + ingameToUrlPath('live/$id');
    }

    private static function ingameToUrlPath(ingamePath:String)
    {
        return basepath() + "?p=" + ingamePath;
    }

    private static function basepath():String
    {
        if (Browser.location.hostname == "intellector.info")
            return "/game/";
        else 
            return "/";
    }
}