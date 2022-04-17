package net;

import struct.PieceColor;
import utils.TimeControl;
import struct.ActualizationData;

class Requests
{
    public static function getGame(id:Int, onOver:ActualizationData->Void, onCurrent:ActualizationData->Void, onNotFound:Void->Void)
    {
        Networker.eventQueue.addHandler(getGame_handler.bind(onOver, onCurrent, onNotFound));
        Networker.emitEvent(GetGame(id));
    }

    private static function getGame_handler(onOver:ActualizationData->Void, onCurrent:ActualizationData->Void, onNotFound:Void->Void, event:ServerEvent):Bool
    {
        switch event
        {
            case GameIsOver(log):
                onOver(new ActualizationData(log));
            case GameIsOngoing(whiteSeconds, blackSeconds, timestamp, pingSubtractionSide, currentLog):
                onCurrent(ActualizationData.current(currentLog, whiteSeconds, blackSeconds, timestamp, pingSubtractionSide));
            case GameNotFound:
                onNotFound();
            default:
                return false;
        }
        return true;
    }

    public static function getOpenChallenge(ownerLogin:String, onInfo:(hostLogin:String, timeControl:TimeControl, color:Null<PieceColor>)->Void, onHostPlaying:(match_id:Int, data:ActualizationData)->Void, onNotFound:Void->Void) 
    {
        Networker.eventQueue.addHandler(getOpenChallenge_handler.bind(onInfo, onHostPlaying, onNotFound));
        Networker.emitEvent(GetOpenChallenge(ownerLogin));
    }

    private static function getOpenChallenge_handler(onInfo:(hostLogin:String, timeControl:TimeControl, color:Null<PieceColor>)->Void, onHostPlaying:(match_id:Int, data:ActualizationData)->Void, onNotFound:Void->Void, event:ServerEvent):Bool
    {
        switch event
        {
            case OpenChallengeInfo(hostLogin, secsStart, secsBonus, colorStr):
                var timeControl:TimeControl = new TimeControl(secsStart, secsBonus);
                var color:Null<PieceColor> = colorStr != null? PieceColor.createByName(colorStr) : null;
                onInfo(hostLogin, timeControl, color);
            case OpenChallengeHostPlaying(match_id, whiteSeconds, blackSeconds, timestamp, pingSubtractionSide, currentLog):
                onHostPlaying(match_id, ActualizationData.current(currentLog, whiteSeconds, blackSeconds, timestamp, pingSubtractionSide));
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

    public static function getStudy(id:Int, onInfo:String->Void, onNotFound:Void->Void) 
    {
        Networker.eventQueue.addHandler(getStudy_handler.bind(onInfo, onNotFound));
        Networker.emitEvent(GetStudy(id));
    }

    private static function getStudy_handler(onInfo:String->Void, onNotFound:Void->Void, event:ServerEvent) 
    {
        switch event
        {
            case SingleStudy(variantStr):
                onInfo(variantStr);
            case StudyNotFound:
                onNotFound();
            default:
                return false;
        }
        return true;
    }
}