package dict;

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
    public static function getColorName(color:PieceColor) 
    {
        return switch Preferences.language.get()
        {
            case EN: color.getName();
            case RU: color == White? "Белые" : "Черные";
        }
    }

    public static function challengeDetails(startSecs:Int, bonusSecs:Int, color:Null<String>)
    {
        var timeControlStr = '${startSecs/60}+${bonusSecs/1}';
        var colorSuffix:String = color == null? "" : ", " + getColorName(PieceColor.createByName(color));
        return timeControlStr + colorSuffix;
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
            case New(whiteLogin, blackLogin, timeControl, startingSituation, startDatetime):
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
            case PlayerProfile(ownerLogin): 
                translations = [ownerLogin, ownerLogin];
            case ChallengeJoining(_, params):
                translations = ['Challenge by ${params.ownerLogin}', 'Вызов ${params.ownerLogin}'];
            default:
        }

        return Dictionary.chooseTranslation(translations);
    }

    public static function getResolution(outcome:Null<Outcome>, winner:Null<PieceColor>):String
    {
        if (winner == null)
            return Dictionary.getPhrase(GAME_RESOLUTION_GAME_IN_PROGRESS);
        else if (winner == null)
            return Dictionary.getPhrase(GAME_RESOLUTION_OUTCOME_SENTENCE(outcome, null));
        else
            return Dictionary.getPhrase(GAME_RESOLUTION_OUTCOME_SENTENCE(outcome, winner)) + ' • ' + Dictionary.getPhrase(GAME_RESOLUTION_WINNER_SENTENCE(winner));
    }
}