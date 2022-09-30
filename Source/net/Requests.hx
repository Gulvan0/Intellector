package net;

import net.shared.OpenChallengeData;
import net.shared.TimeControlType;
import net.shared.GameInfo;
import net.shared.StudyInfo;
import net.shared.ProfileData;
import struct.ChallengeParams;
import dict.Dictionary;
import gfx.Dialogs;
import gfx.SceneManager;
import serialization.GameLogParser;
import struct.PieceColor;
import utils.TimeControl;
import net.shared.ClientEvent;
import net.shared.ServerEvent;

typedef GetGamesCallback = (games:Array<GameInfo>, hasNext:Bool) -> Void;
typedef GetStudiesCallback = (studyMap:Map<Int, StudyInfo>, hasNext:Bool) -> Void;

class Requests
{
    public static function getGame(id:Int)
    {
        Networker.addHandler(getGame_handler.bind(id));
        Networker.emitEvent(GetGame(id));
    }

    private static function getGame_handler(id:Int, event:ServerEvent):Bool
    {
        switch event
        {
            case GameIsOver(log):
                var parsedData:GameLogParserOutput = GameLogParser.parse(log);
		        SceneManager.toScreen(LiveGame(id, Past(parsedData, null)));
            case GameIsOngoing(whiteSeconds, blackSeconds, timestamp, currentLog):
                var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
		        if (LoginManager.isLogged() || parsedData.getPlayerColor() == null)
			        SceneManager.toScreen(LiveGame(id, Ongoing(parsedData, whiteSeconds, blackSeconds, timestamp, parsedData.whiteLogin)));
		        else
			        SceneManager.toScreen(LiveGame(id, Ongoing(parsedData, whiteSeconds, blackSeconds, timestamp, null)));
            case GameNotFound:
                SceneManager.toScreen(MainMenu);
            default:
                return false;
        }
        return true;
    }

    public static function getOpenChallenge(ownerLogin:String) 
    {
        Networker.addHandler(getOpenChallenge_handler.bind(ownerLogin));
        Networker.emitEvent(GetOpenChallenge(ownerLogin));
    }

    private static function getOpenChallenge_handler(ownerLogin:String, event:ServerEvent):Bool
    {
        switch event
        {
            case OpenChallengeInfo(id, paramsStr):
                var params:ChallengeParams = ChallengeParams.deserialize(paramsStr);
                SceneManager.toScreen(ChallengeJoining(id, params));
            case OpenChallengeHostPlaying(match_id, whiteSeconds, blackSeconds, timestamp, currentLog):
                var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
                SceneManager.toScreen(LiveGame(match_id, Ongoing(parsedData, whiteSeconds, blackSeconds, timestamp, ownerLogin)));
            case OpenchallengeNotFound:
                SceneManager.toScreen(MainMenu);
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
                Dialogs.miniProfile(login, data);
            default:
                return false;
        }
        return true;
    }

    public static function getPlayerProfile(login:String) 
    {
        Networker.addHandler(getPlayerProfile_handler.bind(login));
        Networker.emitEvent(GetPlayerProfile(login));
    }

    private static function getPlayerProfile_handler(login:String, event:ServerEvent) 
    {
        switch event
        {
            case PlayerProfile(data):
                SceneManager.toScreen(PlayerProfile(login, data));
            case PlayerNotFound:
                SceneManager.toScreen(MainMenu);
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

    private static function getStudy_handler(id:Int,  event:ServerEvent) 
    {
        switch event
        {
            case SingleStudy(info):
                SceneManager.toScreen(Analysis(info.variantStr, 0, id, info));
            case StudyNotFound:
                SceneManager.toScreen(MainMenu);
                Dialogs.alert(REQUESTS_ERROR_STUDY_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function createStudy(params:StudyInfo) 
    {
        Networker.addHandler(createStudy_handler);
        Networker.emitEvent(CreateStudy(params));
    }

    private static function createStudy_handler(event:ServerEvent) 
    {
        switch event
        {
            case StudyCreated(id, info):
                SceneManager.updateAnalysisStudyInfo(id, info);
            default:
                return false;
        }
        return true;
    }

    public static function followPlayer(login:String)
    {
        Networker.addHandler(followPlayer_handler.bind(login));
        Networker.emitEvent(FollowPlayer(login));
    }

    private static function followPlayer_handler(login:String, event:ServerEvent)
    {
        switch event
        {
            case SpectationData(match_id, whiteSeconds, blackSeconds, timestamp, currentLog): 
		        var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
                SceneManager.toScreen(LiveGame(match_id, Ongoing(parsedData, whiteSeconds, blackSeconds, timestamp, login)));
            case PlayerNotInGame:
                Dialogs.alert(REQUESTS_ERROR_PLAYER_NOT_IN_GAME, REQUESTS_ERROR_DIALOG_TITLE);
            case PlayerOffline:
                Dialogs.alert(REQUESTS_ERROR_PLAYER_OFFLINE, REQUESTS_ERROR_DIALOG_TITLE);
            case PlayerNotFound:
                Dialogs.alert(REQUESTS_ERROR_PLAYER_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function getCurrentGames(callback:Array<{id:Int, currentLog:String}>->Void)
    {
        Networker.addHandler(getCurrentGames_handler.bind(callback));
        Networker.emitEvent(GetCurrentGames);
    }

    private static function getCurrentGames_handler(callback:Array<{id:Int, currentLog:String}>->Void, event:ServerEvent)
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

    public static function getOpenChallenges(callback:Array<OpenChallengeData>->Void)
    {
        Networker.addHandler(getOpenChallenges_handler.bind(callback));
        Networker.emitEvent(GetOpenChallenges);
    }

    private static function getOpenChallenges_handler(callback:Array<OpenChallengeData>->Void, event:ServerEvent)
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
}