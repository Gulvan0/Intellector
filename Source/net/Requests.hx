package net;

import gfx.components.Dialogs;
import gfx.ScreenManager;
import serialization.GameLogParser;
import struct.PieceColor;
import utils.TimeControl;

class Requests
{
    public static function getGame(id:Int)
    {
        Networker.eventQueue.addHandler(getGame_handler.bind(id));
        Networker.emitEvent(GetGame(id));
    }

    private static function getGame_handler(id:Int, event:ServerEvent):Bool
    {
        switch event
        {
            case GameIsOver(log):
                var parsedData:GameLogParserOutput = GameLogParser.parse(log);
		        ScreenManager.toScreen(LiveGame(id, Past(parsedData)));
            case GameIsOngoing(whiteSeconds, blackSeconds, timestamp, currentLog):
                var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
		        if (LoginManager.login == null || parsedData.getPlayerColor() == null)
			        ScreenManager.toScreen(LiveGame(id, Ongoing(parsedData, whiteSeconds, blackSeconds, timestamp, parsedData.whiteLogin)));
		        else
			        ScreenManager.toScreen(LiveGame(id, Ongoing(parsedData, whiteSeconds, blackSeconds, timestamp, null)));
            case GameNotFound:
                ScreenManager.toScreen(MainMenu);
            default:
                return false;
        }
        return true;
    }

    public static function getOpenChallenge(ownerLogin:String) 
    {
        Networker.eventQueue.addHandler(getOpenChallenge_handler.bind(ownerLogin));
        Networker.emitEvent(GetOpenChallenge(ownerLogin));
    }

    private static function getOpenChallenge_handler(ownerLogin:String, event:ServerEvent):Bool
    {
        switch event
        {
            case OpenChallengeInfo(hostLogin, secsStart, secsBonus, colorStr):
                var timeControl:TimeControl = new TimeControl(secsStart, secsBonus);
                var color:Null<PieceColor> = colorStr != null? PieceColor.createByName(colorStr) : null;
                ScreenManager.toScreen(ChallengeJoining(hostLogin, timeControl, color));
            case OpenChallengeHostPlaying(match_id, whiteSeconds, blackSeconds, timestamp, currentLog):
                var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
                ScreenManager.toScreen(LiveGame(match_id, Ongoing(parsedData, whiteSeconds, blackSeconds, timestamp, ownerLogin)));
            case OpenchallengeNotFound:
                ScreenManager.toScreen(MainMenu);
                Dialogs.alert("Вызов не найден", "Ошибка");
            default:
                return false;
        }
        return true;
    }

    public static function getPlayerProfile(login:String) 
    {
        Networker.eventQueue.addHandler(getPlayerProfile_handler.bind(login));
        Networker.emitEvent(GetPlayerProfile(login));
    }

    private static function getPlayerProfile_handler(login:String, event:ServerEvent) 
    {
        switch event
        {
            case PlayerProfile(recentGamesStr, recentStudiesStr, hasMoreGames, hasMoreStudies):
                //TODO: Implement properly
            case PlayerNotFound:
                ScreenManager.toScreen(MainMenu);
                Dialogs.alert("Игрок не найден", "Ошибка");
            default:
                return false;
        }
        return true;
    }

    public static function getStudy(id:Int) 
    {
        Networker.eventQueue.addHandler(getStudy_handler.bind(id));
        Networker.emitEvent(GetStudy(id));
    }

    private static function getStudy_handler(id:Int,  event:ServerEvent) 
    {
        switch event
        {
            case SingleStudy(name, variantStr):
                ScreenManager.toScreen(Analysis(variantStr, id, name));
            case StudyNotFound:
                ScreenManager.toScreen(MainMenu);
                Dialogs.alert("Студия не найдена", "Ошибка");
            default:
                return false;
        }
        return true;
    }

    public static function watchPlayer(login:String)
    {
        Networker.eventQueue.addHandler(watchPlayer_handler.bind(login));
        Networker.emitEvent(Spectate(login));
    }

    private static function watchPlayer_handler(login:String, event:ServerEvent)
    {
        switch event
        {
            case SpectationData(match_id, whiteSeconds, blackSeconds, timestamp, currentLog): 
		        var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
                ScreenManager.toScreen(LiveGame(match_id, Ongoing(parsedData, whiteSeconds, blackSeconds, timestamp, login)));
            case PlayerNotInGame:
                Dialogs.alert("В настоящий момент игрок не участвует в партии", "Ошибка");
            case PlayerOffline:
                Dialogs.alertCallback("Игрок не в сети", "Ошибка");
            case PlayerNotFound:
                Dialogs.alertCallback("Игрок не найден", "Ошибка");
            default:
                return false;
        }
        return true;
    }
}