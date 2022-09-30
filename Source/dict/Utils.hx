package dict;

import net.shared.TimeControlType;
import dict.utils.TimePhrases;
import dict.utils.OutcomePhrases;
import utils.SpecialChar;
import net.shared.UserStatus;
import gfx.game.LiveGameConstructor;
import utils.StringUtils;
import utils.TimeControl;
import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;
import gfx.ScreenType;
import struct.Outcome;
import Preferences.Markup;
import struct.PieceColor;

class Utils
{
    public static function getColorName(color:PieceColor):String
    {
        return switch Preferences.language.get()
        {
            case EN: color.getName();
            case RU: color == White? "Белые" : "Черные";
        }
    }

    public static function getTimeControlName(type:TimeControlType):String
    {
        return switch type {
            case Correspondence: Dictionary.getPhrase(CORRESPONDENCE_TIME_CONTROL_NAME);
            default: type.getName();
        }
    }

    public static function getUserStatusText(status:UserStatus) 
    {
        switch status 
        {
            case Offline(secondsSinceLastAction):
                var activityStr:String = getTimePassedString(secondsSinceLastAction);
                return Dictionary.getPhrase(PROFILE_STATUS_TEXT(status), [activityStr]);
            case Online, InGame:
                return Dictionary.getPhrase(PROFILE_STATUS_TEXT(status));
        }
    }

    public static function getTimePassedString(secsPassed:Float):String
    {
        return TimePhrases.getTimePassedString(secsPassed);
    }

    public static function getPlayerDisconnectedMessage(playerColor:PieceColor)
    {
        return Dictionary.getPhrase(OPPONENT_DISCONNECTED_MESSAGE, [getColorName(playerColor)]);
    }

    public static function getPlayerReconnectedMessage(playerColor:PieceColor)
    {
        return Dictionary.getPhrase(OPPONENT_RECONNECTED_MESSAGE, [getColorName(playerColor)]);
    }

    private static function getLiveGameScreenTitle(id:Int, constructor:LiveGameConstructor):Array<String>
    {
        switch constructor 
        {
            case New(whiteLogin, blackLogin, _, timeControl, startingSituation, startDatetime):
                var opponentLogin:String = LoginManager.isPlayer(whiteLogin)? blackLogin : whiteLogin;
                return ['Playing vs $opponentLogin', 'Игра против $opponentLogin'];
            case Ongoing(parsedData, whiteSeconds, blackSeconds, timeValidAtTimestamp, followedPlayerLogin):
                if (followedPlayerLogin != null)
                    return ['Spectating: ${parsedData.whiteLogin} vs ${parsedData.blackLogin}', 'Наблюдение: ${parsedData.whiteLogin} против ${parsedData.blackLogin}'];
                else
                {
                    var opponentLogin:String = LoginManager.isPlayer(parsedData.whiteLogin)? parsedData.blackLogin : parsedData.whiteLogin;
                    return ['Playing vs $opponentLogin', 'Игра против $opponentLogin'];
                }
            case Past(parsedData, _):
                return ['Game $id: ${parsedData.whiteLogin} vs ${parsedData.blackLogin}', 'Игра $id: ${parsedData.whiteLogin} против ${parsedData.blackLogin}'];
        }
    }

    public static function getScreenTitle(type:ScreenType):String
    {
        var translations = [null, null];
        
        switch type 
        {
            case MainMenu: 
                translations = ["Home", "Главная"];
            case Analysis(_, _, exploredStudyID, exploredStudyName):
                if (exploredStudyName != null)
                {
                    var shortenedName:String = StringUtils.shorten(exploredStudyName);
                    translations = ['Study $shortenedName ($exploredStudyID) | Analysis Board', 'Студия $shortenedName ($exploredStudyID) | Доска анализа'];
                }
                else
                    translations = ["Analysis Board", "Доска анализа"];
            case LiveGame(gameID, constructor): 
                translations = getLiveGameScreenTitle(gameID, constructor);
            case PlayerProfile(ownerLogin, _): 
                translations = ['$ownerLogin\'s profile', 'Профиль $ownerLogin'];
            case ChallengeJoining(_, params):
                translations = ['Challenge by ${params.ownerLogin}', 'Вызов ${params.ownerLogin}'];
            default:
        }

        return Dictionary.chooseTranslation(translations);
    }

    public static function getSpectatorGameOverDialogMessage(outcome:Outcome, whiteLogin:String, blackLogin:String)
    {
        return OutcomePhrases.getSpectatorGameOverDialogMessage(outcome, whiteLogin, blackLogin);
    }

    public static function getPlayerGameOverDialogMessage(outcome:Outcome, playerColor:PieceColor, newPersonalElo:Null<Int>)
    {
        return OutcomePhrases.getPlayerGameOverDialogMessage(outcome, playerColor, newPersonalElo);
    }

    public static function getResolution(outcome:Null<Outcome>):String
    {
        return OutcomePhrases.getResolution(outcome);
    }

    public static function chatboxGameOverMessage(outcome:Outcome):String
    {
        return OutcomePhrases.chatboxGameOverMessage(outcome);
    }
}