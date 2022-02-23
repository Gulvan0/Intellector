package url;

import js.Browser;

class URLEditor 
{
    public static function clear() 
    {
        setPath("");
    }

    public static function setPath(path:String)
    {
        if (StringTools.startsWith(path, "/"))
            path = path.substr(1);
        Browser.window.history.pushState({}, "Intellector", ingameToUrlPath(path));
    }

    //TODO: Move to screens
    /*public static function assignID(id:Int) 
    {
        Browser.window.history.pushState({}, "Intellector", pathname() + "?id=" + id);
    }

    public static function assignProfileLogin(login:String) 
    {
        Browser.window.history.pushState({}, "Intellector", pathname() + "?p=" + login);
    }*/

    //TODO: Update
    public static function getChallengeLink(login:String):String
    {
        return '${Browser.location.host}${Browser.location.pathname}?ch=${login}';
    }

    //TODO: Update
    public static function getGameLink(id:String):String
    {
        return '${Browser.location.host}${Browser.location.pathname}?id=${id}';
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