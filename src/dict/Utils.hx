package dict;

import engine.BotFactory;
import net.shared.utils.PlayerRef;
import net.shared.EloValue;
import net.shared.TimeControlType;
import dict.utils.TimePhrases;
import dict.utils.OutcomePhrases;
import utils.SpecialChar;
import net.shared.dataobj.UserStatus;
import gfx.game.LiveGameConstructor;
import utils.StringUtils;
import utils.TimeControl;
import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;
import gfx.ScreenType;
import net.shared.Outcome;
import net.shared.PieceColor;

class Utils
{
    public static function getColorName(color:PieceColor, ?lang:Language):String
    {
        if (lang == null)
            lang = Preferences.language.get();
        return switch lang
        {
            case EN: color.getName();
            case RU: color == White? "Белые" : "Черные";
        }
    }

    public static function guestName(guestID:String):String
    {
        return 'Guest $guestID';
    }

    public static function playerRef(ref:PlayerRef):String 
    {
        return switch ref.concretize() 
        {
            case Normal(login): login;
            case Guest(guestID): guestName(guestID);
            case Bot(botHandle): BotFactory.botNameByHandle(botHandle);
        }
    }

    public static function opponentRef(whiteRef:String, blackRef:String):String
    {
        return LoginManager.isPlayer(whiteRef)? playerRef(blackRef) : playerRef(whiteRef);
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

    private static function getLiveGameScreenTitle(id:Int, constructor:LiveGameConstructor):Array<String>
    {
        switch constructor 
        {
            case New(whiteRef, blackRef, _, _, _, _):
                var opponent:String = opponentRef(whiteRef, blackRef);
                return ['Playing vs $opponent', 'Игра против $opponent'];
            case Ongoing(parsedData, _, _):
                if (!parsedData.isPlayerParticipant())
                {
                    var whiteStr:String = playerRef(parsedData.whiteRef);
                    var blackStr:String = playerRef(parsedData.blackRef);
                    return ['Spectating: $whiteStr vs $blackStr', 'Наблюдение: $whiteStr против $blackStr'];
                }
                else
                {
                    var opponent:String = opponentRef(parsedData.whiteRef, parsedData.blackRef);
                    return ['Playing vs $opponent', 'Игра против $opponent'];
                }
            case Past(parsedData, _):
                var whiteStr:String = playerRef(parsedData.whiteRef);
                var blackStr:String = playerRef(parsedData.blackRef);
                return ['Game $id: $whiteStr vs $blackStr', 'Игра $id: $whiteStr против $blackStr'];
        }
    }

    public static function getScreenTitle(type:ScreenType):String
    {
        var translations = [null, null];
        
        switch type 
        {
            case MainMenu: 
                translations = ["Home", "Главная"];
            case Analysis(_, _, exploredStudyData):
                if (exploredStudyData != null)
                {
                    var shortenedName:String = StringUtils.shorten(exploredStudyData.info.name);
                    translations = ['Study $shortenedName (${exploredStudyData.id}) | Analysis Board', 'Студия $shortenedName (${exploredStudyData.id}) | Доска анализа'];
                }
                else
                    translations = ["Analysis Board", "Доска анализа"];
            case LiveGame(gameID, constructor): 
                translations = getLiveGameScreenTitle(gameID, constructor);
            case PlayerProfile(ownerLogin, _): 
                translations = ['$ownerLogin\'s profile', 'Профиль $ownerLogin'];
            case ChallengeJoining(data):
                translations = ['Challenge by ${data.ownerLogin}', 'Вызов ${data.ownerLogin}'];
            default:
        }

        return Dictionary.chooseTranslation(translations);
    }

    public static function getSpectatorGameOverDialogMessage(outcome:Outcome, whiteRef:String, blackRef:String)
    {
        return OutcomePhrases.getSpectatorGameOverDialogMessage(outcome, playerRef(whiteRef), playerRef(blackRef));
    }

    public static function getPlayerGameOverDialogMessage(outcome:Outcome, playerColor:PieceColor, newPersonalElo:Null<EloValue>)
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