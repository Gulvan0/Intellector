package dict;

import gfx.profile.data.UserStatus;
import gfx.game.LiveGameConstructor;
import utils.StringUtils;
import utils.TimeControl;
import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;
import gfx.ScreenType;
import struct.Outcome;
import Preferences.Markup;
import struct.PieceColor;

private enum SimpleTimeInterval
{
    LessThanASecond;
    Seconds(cnt:Int);
    Minutes(cnt:Int);
    Hours(cnt:Int);
    Days(cnt:Int);
    Years(cnt:Int);
}

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
        var interval:SimpleTimeInterval = secsToInterval(secsPassed);

        return switch Preferences.language.get()
        {
            case EN: getTimePassedEnglish(interval);
            case RU: getTimePassedRussian(interval);
        }
    }

    private static function secsToInterval(secs:Float):SimpleTimeInterval
    {
        if (secs < 1)
            return LessThanASecond;

        var seconds:Int = Math.floor(secs);

        if (seconds < 60)
            return Seconds(seconds);

        var mins:Int = Math.floor(seconds / 60);

        if (mins < 60)
            return Minutes(mins);

        var hours:Int = Math.floor(mins / 60);

        if (hours < 24)
            return Hours(hours);

        var days:Int = Math.floor(hours / 24);

        if (days < 365)
            return Days(days);

        var years:Int = Math.floor(days / 365);

        return Years(years);
    }

    private static function getTimePassedEnglish(interval:SimpleTimeInterval):String
    {
        return switch interval 
        {
            case LessThanASecond: "Just now";
            case Seconds(1): "A second ago";
            case Seconds(cnt): '$cnt seconds ago';
            case Minutes(1): "A minute ago";
            case Minutes(cnt): '$cnt minutes ago';
            case Hours(1): "An hour ago";
            case Hours(cnt): '$cnt hours ago';
            case Days(1): "Yesterday";
            case Days(cnt): '$cnt days ago';
            case Years(1): "A year ago";
            case Years(cnt): '$cnt years ago';
        }
    }

    private static function getTimePassedRussian(interval:SimpleTimeInterval):String
    {
        return switch interval 
        {
            case LessThanASecond: "Только что";
            case Seconds(1): "Секунду назад";
            case Seconds(cnt) if (cnt % 100 >= 11 && cnt % 100 <= 14): '$cnt секунд назад';
            case Seconds(cnt) if (cnt % 10 == 1): '$cnt секунду назад';
            case Seconds(cnt) if (cnt % 10 >= 2 && cnt % 10 <= 4): '$cnt секунды назад';
            case Seconds(cnt): '$cnt секунд назад';
            case Minutes(1): "Минуту назад";
            case Minutes(cnt) if (cnt % 100 >= 11 && cnt % 100 <= 14): '$cnt минут назад';
            case Minutes(cnt) if (cnt % 10 == 1): '$cnt минуту назад';
            case Minutes(cnt) if (cnt % 10 >= 2 && cnt % 10 <= 4): '$cnt минуты назад';
            case Minutes(cnt): '$cnt минут назад';
            case Hours(1): "Час назад";
            case Hours(cnt) if (cnt % 100 >= 11 && cnt % 100 <= 14): '$cnt часов назад';
            case Hours(cnt) if (cnt % 10 == 1): '$cnt час назад';
            case Hours(cnt) if (cnt % 10 >= 2 && cnt % 10 <= 4): '$cnt часа назад';
            case Hours(cnt): '$cnt часов назад';
            case Days(1): "Вчера";
            case Days(cnt) if (cnt % 100 >= 11 && cnt % 100 <= 14): '$cnt дней назад';
            case Days(cnt) if (cnt % 10 == 1): '$cnt день назад';
            case Days(cnt) if (cnt % 10 >= 2 && cnt % 10 <= 4): '$cnt дня назад';
            case Days(cnt): '$cnt дней назад';
            case Years(1): "Год назад";
            case Years(cnt) if (cnt % 100 >= 11 && cnt % 100 <= 14): '$cnt лет назад';
            case Years(cnt) if (cnt % 10 == 1): '$cnt год назад';
            case Years(cnt) if (cnt % 10 >= 2 && cnt % 10 <= 4): '$cnt года назад';
            case Years(cnt): '$cnt лет назад';
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
            case New(whiteLogin, blackLogin, _, _, timeControl, startingSituation, startDatetime):
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

    public static function getResolution(outcome:Null<Outcome>):String
    {
        var translations = switch outcome 
        {
            case null: ["Game is in progress", "Идет игра"];
            case Mate(White): ["Fatum • White is victorious", "Фатум • Белые победили"];
            case Breakthrough(White): ["Breakthrough • White is victorious", "Прорыв • Белые победили"];
            case Timeout(White): ["Black lost on time • White is victorious", "Черные просрочили время • Белые победили"];
            case Resign(White): ["Black resigned • White is victorious", "Черные сдались • Белые победили"];
            case Abandon(White): ["Black left the game • White is victorious", "Черные покинули игру • Белые победили"];
            case Mate(Black): ["Fatum • Black is victorious", "Фатум • Черные победили"];
            case Breakthrough(Black): ["Breakthrough • Black is victorious", "Прорыв • Черные победили"];
            case Timeout(Black): ["White lost on time • Black is victorious", "Белые просрочили время • Черные победили"];
            case Resign(Black): ["White resigned • Black is victorious", "Белые сдались • Черные победили"];
            case Abandon(Black): ["White left the game • Black is victorious", "Белые покинули игру • Черные победили"];
            case DrawAgreement: ["Draw by agreement", "Ничья по согласию"];
            case Repetition: ["Draw by repetition", "Ничья по троекратному повторению"];
            case NoProgress: ["Draw by sixty-move rule", "Ничья по правилу 60 ходов"];
            case Abort: ["Game aborted", "Игра прервана"];
        }
        return Dictionary.chooseTranslation(translations);
    }

    public static function chatboxGameOverMessage(outcome:Outcome):String
    {
        var lang:Language = Preferences.language.get();
        switch outcome 
        {
            case Mate(winnerColor), Breakthrough(winnerColor):
                var winnerStr:String = Utils.getColorName(winnerColor);
                if (lang == EN)
                    return '$winnerStr won';
                else
                    return '$winnerStr победили';
            case Timeout(winnerColor):
                var loserStr:String = Utils.getColorName(opposite(winnerColor));
                if (lang == EN)
                    return '$loserStr lost on time';
                else
                    return '$loserStr просрочили время';
            case Resign(winnerColor):
                var loserStr:String = Utils.getColorName(opposite(winnerColor));
                if (lang == EN)
                    return '$loserStr resigned';
                else
                    return '$loserStr сдались';
            case Abandon(winnerColor):
                var loserStr:String = Utils.getColorName(opposite(winnerColor));
                if (lang == EN)
                    return '$loserStr left the game';
                else
                    return '$loserStr покинули игру';
            case DrawAgreement:
                if (lang == EN)
                    return 'Game ended with a draw (mutual agreement)';
                else
                    return 'Игра окончена вничью (по договоренности)';
            case Repetition:
                if (lang == EN)
                    return 'Game ended with a draw (threefold repetition)';
                else
                    return 'Игра окончена вничью (по троекратному повторению)';
            case NoProgress:
                if (lang == EN)
                    return 'Game ended with a draw (sixty-move rule)';
                else
                    return 'Игра окончена вничью (по правилу 60 ходов)';
            case Abort:
                if (lang == EN)
                    return 'Game aborted';
                else
                    return 'Игра прервана';
        }       
    }
}