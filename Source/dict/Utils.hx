package dict;

import utils.StringUtils;
import utils.TimeControl;
import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;
import gfx.ScreenType;
import struct.Outcome;
import Preferences.Markup;
import gfx.screens.MainMenu.MainMenuButton;
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
    
    public static function getMainMenuBtnText(type:MainMenuButton):String
    {
        var phrase:Phrase = switch type 
        {
            case SendChallenge: SEND_CHALLENGE;
            case OpenChallenge: OPEN_CHALLENGE_BTN;
            case AnalysisBoard: ANALYSIS_BTN;
            case Spectate: SPECTATE_BTN;
            case Profile: PROFILE_BTN;
            case Settings: SETTINGS_BTN;
            case LogOut: LOG_OUT_BTN;
        }
        return Dictionary.getPhrase(phrase);
    }

    public static function getGameOverExplanation(reason:Outcome):String
    {
        var phrase:Phrase = switch reason
		{
			case Mate: GAME_OVER_REASON_MATE;
			case Breakthrough: GAME_OVER_REASON_BREAKTHROUGH;
			case Timeout: GAME_OVER_REASON_TIMEOUT;
			case Resign: GAME_OVER_REASON_RESIGN;
			case Abandon: GAME_OVER_REASON_DISCONNECT;
			case Repetition: GAME_OVER_REASON_THREEFOLD;
			case NoProgress: GAME_OVER_REASON_HUNDRED;
            case DrawAgreement: GAME_OVER_REASON_AGREEMENT;
            case Abort: GAME_OVER_REASON_ABORT;
		};
        return Dictionary.getPhrase(phrase);
    }

    public static function challengeDetails(startSecs:Int, bonusSecs:Int, color:Null<String>)
    {
        var timeControlStr = '${startSecs/60}+${bonusSecs/1}';
        var colorSuffix:String = color == null? "" : ", " + getColorName(PieceColor.createByName(color));
        return timeControlStr + colorSuffix;
    }

    public static function getMatchlistResultText(winner:Null<PieceColor>, outcome:Null<Outcome>) 
    {
        return getMatchlistWinnerText(winner) + " (" + getMatchlistOutcomeText(outcome) + ")";
    }

    public static function getPlayerDisconnectedMessage(playerColor:PieceColor)
    {
        return Dictionary.getPhrase(OPPONENT_DISCONNECTED_MESSAGE, [getColorName(playerColor)]);
    }

    public static function getPlayerReconnectedMessage(playerColor:PieceColor)
    {
        return Dictionary.getPhrase(OPPONENT_RECONNECTED_MESSAGE, [getColorName(playerColor)]);
    }

    public static function getScreenTitle(type:ScreenType):String
    {
        var translations = [null, null];
        
        switch type 
        {
            case MainMenu: 
                translations = ["Home", "Главная"];
            case Analysis(_, exploredStudyID, exploredStudyName):
                if (exploredStudyName != null)
                {
                    var shortenedName:String = StringUtils.shorten(exploredStudyName);
                    translations = ['Study $shortenedName ($exploredStudyID) | Analysis Board', 'Студия $shortenedName ($exploredStudyID) | Доска анализа'];
                }
                else
                    translations = ["Analysis Board", "Доска анализа"];
            case StartedPlayableGame(gameID, whiteLogin, blackLogin, timeControl, playerColor): 
                var opponentLogin:String = playerColor == White? blackLogin : whiteLogin;
                translations = ['Play $opponentLogin', 'Игра $opponentLogin'];
            case ReconnectedPlayableGame(gameID, data): 
                var opponentLogin:String = data.logParserOutput.getPlayerOpponentLogin();
                translations = ['Play $opponentLogin', 'Игра $opponentLogin'];
            case SpectatedGame(gameID, watchedColor, data):
                var whiteLogin:String = data.logParserOutput.whiteLogin;
                var blackLogin:String = data.logParserOutput.blackLogin;
                translations = ['$whiteLogin vs $blackLogin', '$whiteLogin против $blackLogin'];
            case RevisitedGame(gameID, watchedColor, data): 
                var whiteLogin:String = data.logParserOutput.whiteLogin;
                var blackLogin:String = data.logParserOutput.blackLogin;
                translations = ['$whiteLogin vs $blackLogin', '$whiteLogin против $blackLogin'];
            case PlayerProfile(ownerLogin): 
                translations = [ownerLogin, ownerLogin];
            case LoginRegister:
                translations = ['Sign in', 'Войти'];
            case ChallengeHosting(timeControl, color):
                var tcStr = timeControl.toString();
                translations = ['$tcStr challenge', 'Вызов $tcStr'];
            case ChallengeJoining(challengeOwner, _, _):
                translations = ['Challenge by $challengeOwner', 'Вызов $challengeOwner'];
            default:
        }

        return Dictionary.chooseTranslation(translations);
    }

    public static function getGameOverPopUpMessage(outcome:Outcome, winnerColor:Null<PieceColor>, playerColor:PieceColor):String
    {
        if (outcome == Abort)
            return Dictionary.getPhrase(GAME_OVER_REASON_ABORT);
        
        var result:String;
        var explanation:String = Utils.getGameOverExplanation(outcome);

        if (winnerColor == null)
			result = "½ - ½";
		else if (winnerColor == playerColor)
			result = Dictionary.getPhrase(WIN_MESSAGE_PREAMBLE);
		else 
			result = Dictionary.getPhrase(LOSS_MESSAGE_PREAMBLE);

        return Dictionary.getPhrase(GAME_OVER) + result + explanation;
    }

    //TODO: Rewrite functions below this comment

    private static function getMatchlistWinnerText(color:Null<PieceColor>) 
    {
        if (color == null)
            return switch Preferences.language.get()
            {
                case EN: "Draw";
                case RU: "Ничья";
            }
        else
            return getColorName(color) + switch Preferences.language.get()
            {
                case EN: " won";
                case RU: " победили";
            }
    }

    private static function getMatchlistOutcomeText(outcome:Null<Outcome>) 
    {
        switch Preferences.language.get() 
        {
            case EN: 
                return switch outcome 
                {
                    case Mate: "Mate";
                    case Breakthrough: "Breakthrough";
                    case Resign: "Resignation";
                    case Abandon: "Abandon";
                    case DrawAgreement: "Agreement";
                    case Repetition: "Threefold repetition";
                    case NoProgress: "100-move rule";
                    case Timeout: "Time out";
                    case Abort: "Aborted";
                    case null: "Unknown reason";
                };
            case RU: 
                return switch outcome 
                {
                    case Mate: "Мат";
                    case Breakthrough: "Добегание";
                    case Resign: "Оппонент сдался";
                    case Abandon: "Оппонент покинул игру";
                    case DrawAgreement: "По согласию";
                    case Repetition: "По троекратному повторению";
                    case NoProgress: "По правилу 100 ходов";
                    case Timeout: "Вышло время";
                    case Abort: "Игра прервана";
                    case null: "Неизвестная причина";
                };
        }
    }

    public static function getGameOverChatMessage(winnerColor:Null<PieceColor>, reason:Outcome):String
    {
        return switch reason
		{
			case Mate: getColorName(winnerColor) + Dictionary.getPhrase(GAME_OVER_MESSAGE_SUFFIX_WIN);
			case Breakthrough: getColorName(winnerColor) + Dictionary.getPhrase(GAME_OVER_MESSAGE_SUFFIX_WIN);
			case Timeout: getColorName(opposite(winnerColor)) + Dictionary.getPhrase(GAME_OVER_MESSAGE_SUFFIX_TIMEOUT);
			case Resign: getColorName(opposite(winnerColor)) + Dictionary.getPhrase(GAME_OVER_MESSAGE_SUFFIX_RESIGN);
            case Abandon: getColorName(opposite(winnerColor)) + Dictionary.getPhrase(GAME_OVER_MESSAGE_SUFFIX_DISCONNECT);
            case Abort: Dictionary.getPhrase(GAME_OVER_MESSAGE_ABORT);
			default: Dictionary.getPhrase(GAME_OVER_MESSAGE_DRAW);
        };
    }

    public static function challengeByText(login:String, start:Int, bonus:Int, color:Null<PieceColor>):String
    {
        var timeControlStr = '${start/60}+$bonus';
        var colorStr:String = color == null? Dictionary.getPhrase(COLOR_RANDOM) : getColorName(color);
        return switch Preferences.language.get() {
            case EN: 'Challenge by $login\n$timeControlStr ($login plays as $colorStr)\nShare the link to invite your opponent:';
            case RU: 'Вызов $login\n$timeControlStr (Цвет $login: $colorStr)\nОтправьте эту ссылку-приглашение противнику:';
        }
    }

    public static function getAnalysisTurnColorSelectLabel(color:PieceColor):String 
    {
		return switch Preferences.language.get() {
            case EN: color == White? "White to move" : "Black to move";
            case RU: color == White? "Ход белых" : "Ход черных";
        }
	}
}