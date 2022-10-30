package net;

import net.shared.ChallengeData;
import net.shared.TimeControlType;
import net.shared.GameInfo;
import net.shared.StudyInfo;
import net.shared.ProfileData;
import struct.ChallengeParams;
import dict.Dictionary;
import gfx.Dialogs;
import gfx.SceneManager;
import serialization.GameLogParser;
import net.shared.PieceColor;
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
            case GameIsOngoing(timeData, currentLog):
                var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
                SceneManager.toScreen(LiveGame(id, Ongoing(parsedData, timeData, null)));
            case GameNotFound:
                SceneManager.toScreen(MainMenu);
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
                SceneManager.toScreen(ChallengeJoining(data));
            case OpenChallengeHostPlaying(gameID, timeData, currentLog):
                var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
                SceneManager.toScreen(LiveGame(gameID, Ongoing(parsedData, timeData, null)));
            case OpenChallengeGameEnded(gameID, log):
                var parsedData:GameLogParserOutput = GameLogParser.parse(log);
                SceneManager.toScreen(LiveGame(gameID, Past(parsedData, null)));
            case OpenChallengeNotFound:
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
            case PlayerNotFound:
                Dialogs.alert(REQUESTS_ERROR_PLAYER_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
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
            case SpectationData(gameID, timeData, currentLog): 
		        var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
                SceneManager.toScreen(LiveGame(gameID, Ongoing(parsedData, timeData, login)));
            case FollowSuccess:
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
}