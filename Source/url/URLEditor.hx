package url;

import js.Browser;

class URLEditor 
{
    public static function clear() 
    {
        Browser.window.history.pushState({}, "Intellector", pathname());
    }
    
    public static function assignID(id:Int) 
    {
        Browser.window.history.pushState({}, "Intellector", pathname() + "?id=" + id);
    }

    public static function assignProfileLogin(login:String) 
    {
        Browser.window.history.pushState({}, "Intellector", pathname() + "?p=" + login);
    }

    public static function getChallengeLink(login:String):String
    {
        return '${Browser.location.host}${Browser.location.pathname}?ch=${login}';
    }

    public static function getGameLink(id:String):String
    {
        return '${Browser.location.host}${Browser.location.pathname}?id=${id}';
    }

    private static function pathname():String
    {
        if (Browser.location.hostname == "intellector.info")
            return "/game/";
        else 
            return "/";
    }
}