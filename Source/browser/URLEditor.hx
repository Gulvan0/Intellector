package browser;

import haxe.CallStack;
import dict.Utils;
import js.html.URLSearchParams;
import gfx.ScreenType;
import js.Browser;

class URLEditor 
{
    public static function clear() 
    {
        setPath("");
    }

    public static function setPathByScreen(type:ScreenType)
    {
        setPath(getURLPath(type), Utils.getScreenTitle(type));
    }

    private static function setPath(path:String, ?title:String)
    {
        trace(path, title);
        trace(CallStack.callStack());
        if (StringTools.startsWith(path, "/"))
            path = path.substr(1);
        var fullTitle:String = title != null? title + " - Intellector" : "Intellector";
        if (new URLSearchParams(Browser.location.search).get("p") != path)
            Browser.window.history.pushState({}, fullTitle, ingameToUrlPath(path));
        Browser.document.title = fullTitle;
    }

    public static function getChallengeLink(id:Int):String
    {
        return Browser.location.host + ingameToUrlPath('join/$id');
    }

    public static function getGameLink(id:Int):String
    {
        return Browser.location.host + ingameToUrlPath('live/$id');
    }

    private static function getURLPath(type:ScreenType):String
    {
        return switch type 
        {
            case MainMenu: "home";
            case Analysis(_, _, exploredStudyID, _): exploredStudyID == null? "analysis" : 'study/$exploredStudyID';
            case LanguageSelectIntro(_): "";
            case LiveGame(gameID, _): 'live/$gameID';
            case PlayerProfile(ownerLogin, _): 'player/$ownerLogin';
            case ChallengeJoining(data): 'join/${data.ownerLogin}';
        }
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