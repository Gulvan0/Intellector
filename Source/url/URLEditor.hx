package url;

import js.Browser;

class URLEditor 
{
    public static function clear() 
    {
        #if prod
        Browser.window.history.pushState({}, "Intellector", "/game/");
        #else
        Browser.window.history.pushState({}, "Intellector", "/");
        #end
    }
    
    public static function assignID(id:Int) 
    {
        #if prod
        Browser.window.history.pushState({}, "Intellector", "/game/?id=" + id);
        #else
        Browser.window.history.pushState({}, "Intellector", "/?id=" + id);
        #end
    }

    public static function getChallengeLink(login:String):String
    {
        return '${Browser.location.host}${Browser.location.pathname}?ch=${login}';
    }
}