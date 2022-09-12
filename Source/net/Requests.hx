package net;

import net.shared.OverviewGameData;
import gfx.profile.ProfileData;
import struct.ChallengeParams;
import dict.Dictionary;
import gfx.Dialogs;
import gfx.SceneManager;
import serialization.GameLogParser;
import struct.PieceColor;
import utils.TimeControl;
import net.shared.ClientEvent;
import net.shared.ServerEvent;

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

    public static function getPlayerProfile(login:String) 
    {
        Networker.addHandler(getPlayerProfile_handler.bind(login));
        Networker.emitEvent(GetPlayerProfile(login));
    }

    private static function getPlayerProfile_handler(login:String, event:ServerEvent) 
    {
        switch event
        {
            case PlayerProfile(serializedProfileData):
                var profileData:ProfileData = ProfileData.deserialize(serializedProfileData);
                SceneManager.toScreen(PlayerProfile(login, profileData));
            case PlayerNotFound:
                SceneManager.toScreen(MainMenu);
                Dialogs.alert(REQUESTS_ERROR_PLAYER_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function getPlayerPastGames(login:String, after:Int, pageSize:Int, filterByTimeControl:Null<TimeControlType>, callback:Array<OverviewGameData>->Void, ?hasMoreHandler:Bool->Void)
    {
        var requestedCount:Int = hasMoreHandler != null? pageSize + 1 : pageSize;
        Networker.addHandler(getPlayerGames_handler.bind(callback, pageSize, hasMoreHandler));
        Networker.emitEvent(GetGamesByLogin(login, after, requestedCount, filterByTimeControl));
    }

    public static function getPlayerOngoingGames(login:String, callback:Array<OverviewGameData>->Void)
    {
        Networker.addHandler(getPlayerGames_handler.bind(callback, null, null));
        Networker.emitEvent(GetOngoingGamesByLogin(login));
    }

    private static function getPlayerGames_handler(callback:Array<OverviewGameData>->Void, pageSize:Null<Int>, hasMoreHandler:Null<Bool->Void>, event:ServerEvent) 
    {
        switch event
        {
            case Games(games):
                if (hasMoreHandler != null)
                    if (games.length > pageSize)
                    {
                        callback(games.slice(0, pageSize));
                        hasMoreHandler(true);
                    }
                    else
                    {
                        callback(games);
                        hasMoreHandler(false);
                    }
                else
                    callback(games);
            default:
                return false;
        }
        return true;
    }

    public static function getPlayerStudies(login:String, after:Int, pageSize:Int, filterByTags:Null<Array<String>>, callback:Array<OverviewStudyData>->Void, ?hasMoreHandler:Bool->Void)
    {
        var requestedCount:Int = hasMoreHandler != null? pageSize + 1 : pageSize;
        Networker.addHandler(getPlayerStudies_handler.bind(callback, pageSize, hasMoreHandler));
        Networker.emitEvent(GetStudiesByLogin(login, after, requestedCount, filterByTags));
    }

    private static function getPlayerStudies_handler(callback:Array<OverviewStudyData>->Void, pageSize:Int, hasMoreHandler:Null<Bool->Void>, event:ServerEvent) 
    {
        switch event
        {
            case Studies(studies):
                if (hasMoreHandler != null)
                    if (studies.length > pageSize)
                    {
                        callback(studies.slice(0, pageSize));
                        hasMoreHandler(true);
                    }
                    else
                    {
                        callback(studies);
                        hasMoreHandler(false);
                    }
                else
                    callback(studies);
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
            case SingleStudy(name, variantStr):
                SceneManager.toScreen(Analysis(variantStr, 0, id, name));
            case StudyNotFound:
                SceneManager.toScreen(MainMenu);
                Dialogs.alert(REQUESTS_ERROR_STUDY_NOT_FOUND, REQUESTS_ERROR_DIALOG_TITLE);
            default:
                return false;
        }
        return true;
    }

    public static function watchPlayer(login:String)
    {
        Networker.addHandler(watchPlayer_handler.bind(login));
        Networker.emitEvent(FollowPlayer(login));
    }

    private static function watchPlayer_handler(login:String, event:ServerEvent)
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

    public static function getOpenChallenges(callback:Array<String>->Void)
    {
        Networker.addHandler(getOpenChallenges_handler.bind(callback));
        Networker.emitEvent(GetOpenChallenges);
    }

    private static function getOpenChallenges_handler(callback:Array<String>->Void, event:ServerEvent)
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