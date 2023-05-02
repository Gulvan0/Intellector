package dict;

import engine.BotFactory;
import net.shared.utils.PlayerRef;
import net.shared.EloValue;
import net.shared.TimeControlType;
import dict.utils.TimePhrases;
import dict.utils.OutcomePhrases;
import utils.SpecialChar;
import net.shared.dataobj.UserStatus;
import utils.StringUtils;
import utils.TimeControl;
import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;
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