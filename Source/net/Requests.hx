package net;

import struct.PieceColor;
import utils.TimeControl;

class Requests
{
    public static function getGame(id:Int, onOver:(log:String)->Void, onCurrent:(match_id:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String)->Void, onNotFound:Void->Void)
    {
        Networker.eventQueue.addHandler(getGame_handler.bind(onOver, onCurrent.bind(id), onNotFound));
        Networker.emitEvent(GetGame(id));
    }

    private static function getGame_handler(onOver:(log:String)->Void, onCurrent:(whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String)->Void, onNotFound:Void->Void, event:ServerEvent):Bool
    {
        switch event
        {
            case GameIsOver(log):
                onOver(log);
            case GameIsOngoing(whiteSeconds, blackSeconds, timestamp, currentLog):
                onCurrent(whiteSeconds, blackSeconds, timestamp, currentLog);
            case GameNotFound:
                onNotFound();
            default:
                return false;
        }
        return true;
    }

    public static function getOpenChallenge(ownerLogin:String, onInfo:(hostLogin:String, timeControl:TimeControl, color:Null<PieceColor>)->Void, onHostPlaying:(match_id:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String)->Void, onNotFound:Void->Void) 
    {
        Networker.eventQueue.addHandler(getOpenChallenge_handler.bind(onInfo, onHostPlaying, onNotFound));
        Networker.emitEvent(GetOpenChallenge(ownerLogin));
    }

    private static function getOpenChallenge_handler(onInfo:(hostLogin:String, timeControl:TimeControl, color:Null<PieceColor>)->Void, onHostPlaying:(match_id:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String)->Void, onNotFound:Void->Void, event:ServerEvent):Bool
    {
        switch event
        {
            case OpenChallengeInfo(hostLogin, secsStart, secsBonus, colorStr):
                var timeControl:TimeControl = new TimeControl(secsStart, secsBonus);
                var color:Null<PieceColor> = colorStr != null? PieceColor.createByName(colorStr) : null;
                onInfo(hostLogin, timeControl, color);
            case OpenChallengeHostPlaying(match_id, whiteSeconds, blackSeconds, timestamp, currentLog):
                onHostPlaying(match_id, whiteSeconds, blackSeconds, timestamp, currentLog);
            case OpenchallengeNotFound:
                onNotFound();
            default:
                return false;
        }
        return true;
    }

    public static function getPlayerProfile(login:String, onInfo:Void->Void, onNotFound:Void->Void) 
    {
        Networker.eventQueue.addHandler(getPlayerProfile_handler.bind(onInfo, onNotFound));
        Networker.emitEvent(GetPlayerProfile(login));
    }

    private static function getPlayerProfile_handler(onInfo:Void->Void, onNotFound:Void->Void, event:ServerEvent) 
    {
        switch event
        {
            case PlayerProfile(recentGamesStr, recentStudiesStr, hasMoreGames, hasMoreStudies):
                onInfo(); //TODO: Implement properly
            case PlayerNotFound:
                onNotFound();
            default:
                return false;
        }
        return true;
    }

    public static function getStudy(id:Int, onInfo:(name:String, variantStr:String)->Void, onNotFound:Void->Void) 
    {
        Networker.eventQueue.addHandler(getStudy_handler.bind(onInfo, onNotFound));
        Networker.emitEvent(GetStudy(id));
    }

    private static function getStudy_handler(onInfo:(name:String, variantStr:String)->Void, onNotFound:Void->Void, event:ServerEvent) 
    {
        switch event
        {
            case SingleStudy(name, variantStr):
                onInfo(name, variantStr);
            case StudyNotFound:
                onNotFound();
            default:
                return false;
        }
        return true;
    }

    public static function watchPlayer(login:String, onData:(match_id:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String)->Void, onNotPlaying:Void->Void, onOffline:Void->Void, onNotFound:Void->Void)
    {
        Networker.eventQueue.addHandler(watchPlayer_handler.bind(onData, onNotPlaying, onOffline, onNotFound));
        Networker.emitEvent(Spectate(login));
    }

    private static function watchPlayer_handler(onData:(match_id:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String)->Void, onNotPlaying:Void->Void, onOffline:Void->Void, onNotFound:Void->Void, event:ServerEvent)
    {
        switch event
        {
            case SpectationData(match_id, whiteSeconds, blackSeconds, timestamp, currentLog):
                onData(match_id, whiteSeconds, blackSeconds, timestamp, currentLog);
            case PlayerNotInGame:
                onNotPlaying();
            case PlayerOffline:
                onOffline();
            case PlayerNotFound:
                onNotFound();
            default:
                return false;
        }
        return true;
    }
}