package net;

import gfx.profile.complex_components.MiniProfile;
import net.shared.utils.Build;
import net.shared.dataobj.GreetingResponseData;
import net.shared.dataobj.Greeting;
import net.shared.dataobj.ChallengeData;
import net.shared.TimeControlType;
import net.shared.dataobj.GameInfo;
import net.shared.dataobj.StudyInfo;
import net.shared.dataobj.ProfileData;
import net.shared.dataobj.ChallengeParams;
import dict.Dictionary;
import gfx.Dialogs;
import gfx.scene.SceneManager;
import net.shared.PieceColor;
import net.shared.TimeControl;
import net.shared.ClientEvent;
import net.shared.ServerEvent;

typedef GetGamesCallback = (games:Array<GameInfo>, hasNext:Bool) -> Void;
typedef GetStudiesCallback = (studyMap:Array<StudyInfo>, hasNext:Bool) -> Void;

class Requests
{
    public static function greet(greeting:Greeting, callback:GreetingResponseData->Void)
    {
        Networker.addHandler(greet_handler.bind(callback));
        Networker.emitEvent(Greet(greeting, Build.buildTime(), Config.dict.getInt("min-server-build")));
    }

    private static function greet_handler(callback:GreetingResponseData->Void, event:ServerEvent):Bool
    {
        switch event 
        {
            case GreetingResponse(data):
                callback(data);
                return true;
            default:
                return false;
        }
    }

    public static function signin(login:String, password:String, remember:Bool, onSuccess:Void->Void, onFail:Void->Void) 
    {
        Networker.addHandler(signin_handler.bind(login, password, remember, onSuccess, onFail));
        Networker.emitEvent(Login(login, password));
    }

    private static function signin_handler(login:String, password:String, remember:Bool, onSuccess:Void->Void, onFail:Void->Void, event:ServerEvent) 
    {
        switch event
        {
            case LoginResult(result):
                switch result 
                {
                    case Success(incomingChallenges):
                        LoginManager.assignCredentials(login, password, remember? LongTerm : ShortTerm);
                        GlobalBroadcaster.broadcast(IncomingChallengesBatch(incomingChallenges));
                        onSuccess();
                    case ReconnectionNeeded(incomingChallenges, gameInfo):
                        LoginManager.assignCredentials(login, password, remember? LongTerm : ShortTerm);
                        GlobalBroadcaster.broadcast(IncomingChallengesBatch(incomingChallenges));
                        //TODO: Rewrite
                        /*var parsedData:GameLogParserOutput = GameLogParser.parse(gameInfo.currentLog);
                        SceneManager.toScreen(LiveGame(gameInfo.id, Ongoing(parsedData, gameInfo.timeData, null)));*/
                    case Fail:
                        onFail();
                }
                return true;
            default:
                return false;
        }
    }

    public static function register(login:String, password:String, remember:Bool, onSuccess:Void->Void, onFail:Void->Void) 
    {
        Networker.addHandler(register_handler.bind(login, password, remember, onSuccess, onFail));
        Networker.emitEvent(Register(login, password));
    }

    private static function register_handler(login:String, password:String, remember:Bool, onSuccess:Void->Void, onFail:Void->Void, event:ServerEvent) 
    {
        switch event
        {
            case RegisterResult(result):
                if (result == Success)
                {
                    LoginManager.assignCredentials(login, password, remember? LongTerm : ShortTerm);
                    onSuccess();
                }
                else
                    onFail();
                return true;
            default:
                return false;
        }
    }

    public static function getGame(id:Int)
    {
        Networker.addHandler(getGame_handler.bind(id));
        Networker.emitEvent(GetGame(id));
    }

    private static function getGame_handler(id:Int, event:ServerEvent):Bool
    {
        switch event
        {
            case GameRetrieved(data):
                //TODO: Rewrite
                        /*var parsedData:GameLogParserOutput = GameLogParser.parse(log);
		        SceneManager.toScreen(LiveGame(id, Past(parsedData, null)));*/
                        /*var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
                SceneManager.toScreen(LiveGame(id, Ongoing(parsedData, timeData, null)));*/
            case GameNotFound:
                SceneManager.getScene().toScreen(MainMenu);
            default:
                return false;
        }
        return true;
    }

    public static function getOpenChallenge(id:Int) 
    {
        Networker.addHandler(getOpenChallenge_handler);
        Networker.emitEvent(GetOpenChallenge(id));
    }

    private static function getOpenChallenge_handler(event:ServerEvent):Bool
    {
        switch event
        {
            case OpenChallengeInfo(data):
                SceneManager.getScene().toScreen(ChallengeJoining(data));
            case OpenChallengeAlreadyAccepted(data):
                //TODO: Rewrite
                        /*var parsedData:GameLogParserOutput = GameLogParser.parse(data.currentLog);
                SceneManager.toScreen(LiveGame(data.id, Ongoing(parsedData, data.timeData, null)));*/
                        /*var parsedData:GameLogParserOutput = GameLogParser.parse(log);
                SceneManager.toScreen(LiveGame(gameID, Past(parsedData, null)));*/
            case OpenChallengeNotFound:
                SceneManager.getScene().toScreen(MainMenu);
                Dialogs.alert(REQUESTS_ERROR_CHALLENGE_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function getMiniProfile(login:String) 
    {
        Networker.addHandler(getMiniProfile_handler.bind(login));
        Networker.emitEvent(GetMiniProfile(login));
    }

    private static function getMiniProfile_handler(login:String, event:ServerEvent) 
    {
        switch event
        {
            case MiniProfile(data):
                Dialogs.getQueue().add(new MiniProfile(login, data));
            case PlayerNotFound:
                Dialogs.alert(REQUESTS_ERROR_PLAYER_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function getPlayerProfile(login:String, ?returnToMainOnFailed:Bool = false) 
    {
        Networker.addHandler(getPlayerProfile_handler.bind(login, returnToMainOnFailed));
        Networker.emitEvent(GetPlayerProfile(login));
    }

    private static function getPlayerProfile_handler(login:String, returnToMainOnFailed:Bool, event:ServerEvent) 
    {
        switch event
        {
            case PlayerProfile(data):
                SceneManager.getScene().toScreen(PlayerProfile(login, data));
            case PlayerNotFound:
                if (returnToMainOnFailed)
                    SceneManager.getScene().toScreen(MainMenu);
                Dialogs.alert(REQUESTS_ERROR_PLAYER_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function getPlayerPastGames(login:String, after:Int, pageSize:Int, filterByTimeControl:Null<TimeControlType>, callback:GetGamesCallback)
    {
        Networker.addHandler(getPlayerGames_handler.bind(callback));
        Networker.emitEvent(GetGamesByLogin(login, after, pageSize, filterByTimeControl));
    }

    public static function getPlayerOngoingGames(login:String, callback:GetGamesCallback)
    {
        Networker.addHandler(getPlayerGames_handler.bind(callback));
        Networker.emitEvent(GetOngoingGamesByLogin(login));
    }

    private static function getPlayerGames_handler(callback:GetGamesCallback, event:ServerEvent) 
    {
        switch event
        {
            case Games(games, hasNext):
                callback(games, hasNext);
            case PlayerNotFound:
                Dialogs.alert(REQUESTS_ERROR_PLAYER_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function getPlayerStudies(login:String, after:Int, pageSize:Int, filterByTags:Null<Array<String>>, callback:GetStudiesCallback)
    {
        Networker.addHandler(getPlayerStudies_handler.bind(callback));
        Networker.emitEvent(GetStudiesByLogin(login, after, pageSize, filterByTags));
    }

    private static function getPlayerStudies_handler(callback:GetStudiesCallback, event:ServerEvent) 
    {
        switch event
        {
            case Studies(studies, hasNext):
                callback(studies, hasNext);
            case PlayerNotFound:
                Dialogs.alert(REQUESTS_ERROR_PLAYER_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function getStudy(id:Int) 
    {
        Networker.addHandler(getStudy_handler.bind(id));
        Networker.emitEvent(GetStudy(id));
    }

    private static function getStudy_handler(id:Int, event:ServerEvent) 
    {
        //TODO: Rewrite
        /*switch event
        {
            case SingleStudy(info):
                SceneManager.toScreen(Analysis(info.variantStr, 0, new StudyData(id, ownerLogin, info)));
            case StudyNotFound:
                SceneManager.toScreen(MainMenu);
                Dialogs.alert(REQUESTS_ERROR_STUDY_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }*/
        return true;
    }

    public static function createStudy(params:StudyInfo, onCreated:StudyInfo->Void) 
    {
        Networker.addHandler(createStudy_handler.bind(onCreated));
        Networker.emitEvent(CreateStudy(params));
    }

    private static function createStudy_handler(onCreated:StudyInfo->Void, event:ServerEvent) 
    {
        switch event
        {
            case StudyCreated(info):
                onCreated(info);
            default:
                return false;
        }
        return true;
    }

    public static function followPlayer(login:String, onStartedFollowing:(login:String, activeGameID:Null<Int>)->Void)
    {
        Networker.addHandler(followPlayer_handler.bind(login, onStartedFollowing));
        Networker.emitEvent(FollowPlayer(login));
    }

    private static function followPlayer_handler(login:String, onStartedFollowing:(login:String, activeGameID:Null<Int>)->Void, event:ServerEvent)
    {
        switch event
        {
            case GoToGame(data):
                onStartedFollowing(login, data.gameID);
            case FollowAlreadySpectating(id):
                onStartedFollowing(login, id);
            case FollowSuccess:
                onStartedFollowing(login, null);
                Dialogs.info(REQUESTS_FOLLOW_PLAYER_SUCCESS_DIALOG_TEXT, REQUESTS_FOLLOW_PLAYER_SUCCESS_DIALOG_TITLE);
            case PlayerNotFound:
                Dialogs.alert(REQUESTS_ERROR_PLAYER_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function getCurrentGames(callback:Array<GameInfo>->Void)
    {
        Networker.addHandler(getCurrentGames_handler.bind(callback));
        Networker.emitEvent(GetCurrentGames);
    }

    private static function getCurrentGames_handler(callback:Array<GameInfo>->Void, event:ServerEvent)
    {
        switch event
        {
            case CurrentGames(data):
                callback(data);
                return true;
            default:
                return false;
        }
    }

    public static function getOpenChallenges(callback:Array<ChallengeData>->Void)
    {
        Networker.addHandler(getOpenChallenges_handler.bind(callback));
        Networker.emitEvent(GetOpenChallenges);
    }

    private static function getOpenChallenges_handler(callback:Array<ChallengeData>->Void, event:ServerEvent)
    {
        switch event
        {
            case OpenChallenges(data):
                callback(data);
                return true;
            default:
                return false;
        }
    }

    public static function getRecentGames(callback:Array<GameInfo>->Void)
    {
        Networker.addHandler(getRecentGames_handler.bind(callback));
        Networker.emitEvent(GetRecentGames);
    }

    private static function getRecentGames_handler(callback:Array<GameInfo>->Void, event:ServerEvent)
    {
        switch event
        {
            case RecentGames(data):
                callback(data);
                return true;
            default:
                return false;
        }
    }
}