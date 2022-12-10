package browser;

import haxe.CallStack;
import dict.Utils;
import js.html.URLSearchParams;
import gfx.ScreenType;
import js.Browser;
using hx.strings.Strings;

class Url 
{
    private static var currentTitle:String;

    public static function getCurrentTitle():String
    {
        return currentTitle;
    }

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
        if (StringTools.startsWith(path, "/"))
            path = path.substr(1);
        var fullTitle:String = title != null? title + " - Intellector" : "Intellector";
        if (new URLSearchParams(Browser.location.search).get("p") != path)
            Browser.window.history.pushState({}, fullTitle, ingameToUrlPath(path));
        Browser.document.title = fullTitle;
        Url.currentTitle = fullTitle;
    }

    public static function getChallengeLink(id:Int):String
    {
        return Browser.location.host + ingameToUrlPath('join/$id');
    }

    public static function getGameLink(id:Int):String
    {
        return Browser.location.host + ingameToUrlPath('live/$id');
    }

    public static function isFallback():Bool
    {
        var actualVerPathPrefix:Null<String> = Config.dict.getString("actual-path-prefix");
        var prevVerPathPrefix:Null<String> = Config.dict.getString("prev-path-prefix");

        if (actualVerPathPrefix != null && prevVerPathPrefix != null)
            return Browser.window.location.pathname.startsWith(prevVerPathPrefix);
        else
            return false;
    }

    public static function toFallback():String
    {
        var actualVerPathPrefix:Null<String> = Config.dict.getString("actual-path-prefix");
        var prevVerPathPrefix:Null<String> = Config.dict.getString("prev-path-prefix");

        if (actualVerPathPrefix != null && prevVerPathPrefix != null)
            return Browser.window.location.href.replaceFirstIgnoreCase(actualVerPathPrefix, prevVerPathPrefix);
        else
            return Browser.window.location.href;
    }

    public static function toActual():String
    {
        var actualVerPathPrefix:Null<String> = Config.dict.getString("actual-path-prefix");
        var prevVerPathPrefix:Null<String> = Config.dict.getString("prev-path-prefix");

        if (actualVerPathPrefix != null && prevVerPathPrefix != null)
            return Browser.window.location.href.replaceFirstIgnoreCase(prevVerPathPrefix, actualVerPathPrefix);
        else
            return Browser.window.location.href;
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
        return Browser.location.pathname.split("/").slice(0, 2).join("/") + "/";
    }
}