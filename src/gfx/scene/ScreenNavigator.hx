package gfx.scene;

import net.Requests;
import js.Browser;
import js.html.URLSearchParams;

class ScreenNavigator
{
    public static function navigate()
    {
        var searcher = new URLSearchParams(Browser.location.search);
        if (searcher.has("p"))
        {
            var pagePathParts:Array<String> = searcher.get("p").split('/');
            var section:String = pagePathParts[0];

            navigateToSection(section, pagePathParts.slice(1));
        }
        else if (searcher.has("id")) //* This case was added for the backward compatibility
            navigateToSection("live", [searcher.get("id")]);
        else
            navigateToSection("home", []);
    }

    private static function navigateToSection(section:String, pathPartsAfter:Array<String>)
    {
        switch section
        {
            case "analysis":  
                toAnalysis();
            case "join":
                toOpenChallengeJoining(pathPartsAfter[0]);
            case "player":
                toProfile(pathPartsAfter[0]);
            case "study":
                toStudy(pathPartsAfter[0]);
            case "live": 
                toGame(pathPartsAfter[0]);
            default:
                SceneManager.getScene().toScreen(MainMenu);
        }
    }

    public static function toAnalysis() 
    {
        SceneManager.getScene().toScreen(NewAnalysisBoard);
    }

    private static function toOpenChallengeJoining(idStr:String) 
    {
        var id:Null<Int> = Std.parseInt(idStr);
        if (id != null)
            Requests.getOpenChallenge(id);
        else
            SceneManager.getScene().toScreen(MainMenu);
    }

    private static function toProfile(login:String) 
    {
        Requests.getPlayerProfile(login, true);
    }

    private static function toStudy(idStr:String) 
    {
        var id:Null<Int> = Std.parseInt(idStr);
        if (id != null)
            Requests.getStudy(id);
        else
            SceneManager.getScene().toScreen(MainMenu);
    }

    private static function toGame(idStr:String) 
    {
        var id:Null<Int> = Std.parseInt(idStr);
        if (id != null)
            Requests.getGame(id);
        else
            SceneManager.getScene().toScreen(MainMenu);
    }
}