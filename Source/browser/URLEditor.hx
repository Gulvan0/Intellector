package browser;

import gfx.ScreenType;
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

    public static function getGameLink(id:Int):String
    {
        return Browser.location.host + ingameToUrlPath('live/$id');
    }

    public static function getURLPath(type:ScreenType):String
    {
        return switch type 
        {
            case MainMenu: "home";
            case Analysis(_, exploredStudyID, _): exploredStudyID == null? "analysis" : 'study/$exploredStudyID';
            case LanguageSelectIntro(_): "";
            case StartedPlayableGame(gameID, _, _, _, _): 'live/$gameID';
            case ReconnectedPlayableGame(gameID, _): 'live/$gameID';
            case SpectatedGame(gameID, _, _): 'live/$gameID';
            case RevisitedGame(gameID, _, _): 'live/$gameID';
            case PlayerProfile(ownerLogin): 'player/$ownerLogin';
            case LoginRegister: 'login';
            case ChallengeHosting(_, _): "challenge";
            case ChallengeJoining(challengeOwner, timeControl, color): 'join/$challengeOwner';
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