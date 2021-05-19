package;

import js.Browser;

class URLEditor 
{
    public static function clear() 
    {
        Browser.window.history.pushState({}, "Intellector", "/game/");
    }
    
    public static function assignID(id:Int) 
    {
        Browser.window.history.pushState({}, "Intellector", "/game/?id=" + id);
    }

    public static function getChallengeLink(login:String):String
    {
        return '${Browser.location.host}${Browser.location.pathname}?ch=${login}';
    }
}