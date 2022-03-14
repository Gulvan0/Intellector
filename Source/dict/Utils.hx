package dict;

import gfx.game.GameInfoBox.Outcome;
import Preferences.Markup;
import gfx.screens.MainMenu.MainMenuButton;
import struct.PieceColor;

class Utils
{
    public static function getColorName(color:PieceColor) 
    {
        return switch Preferences.instance.language 
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

    public static function getMarkupOptionText(type:Markup):String
    {
        var phrase:Phrase = switch type 
        {
            case None: SETTINGS_MARKUP_TYPE_NONE;
            case Side: SETTINGS_MARKUP_TYPE_SIDE;
            case Over: SETTINGS_MARKUP_TYPE_OVER;
        }
        return Dictionary.getPhrase(phrase);
    }

    public static function getGameOverExplanation(reason:String):String
    {
        var phrase:Phrase = switch reason
		{
			case 'mate': GAME_OVER_REASON_MATE;
			case 'breakthrough': GAME_OVER_REASON_BREAKTHROUGH;
			case 'timeout': GAME_OVER_REASON_TIMEOUT;
			case 'resignation': GAME_OVER_REASON_RESIGN;
			case 'abandon': GAME_OVER_REASON_DISCONNECT;
			case 'threefoldrepetition': GAME_OVER_REASON_THREEFOLD;
			case 'hundredmoverule': GAME_OVER_REASON_HUNDRED;
            case 'drawagreement': GAME_OVER_REASON_AGREEMENT;
            case 'abort': GAME_OVER_REASON_ABORT;
			default: GAME_OVER_REASON_MATE;
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

    //TODO: Rewrite functions below this comment

    private static function getMatchlistWinnerText(color:Null<PieceColor>) 
    {
        if (color == null)
            return switch Preferences.instance.language 
            {
                case EN: "Draw";
                case RU: "Ничья";
            }
        else
            return getColorName(color) + switch Preferences.instance.language 
            {
                case EN: " won";
                case RU: " победили";
            }
    }

    private static function getMatchlistOutcomeText(outcome:Null<Outcome>) 
    {
        switch Preferences.instance.language 
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
        return switch Preferences.instance.language {
            case EN: 'Challenge by $login\n$timeControlStr ($login plays as $colorStr)\nShare the link to invite your opponent:';
            case RU: 'Вызов $login\n$timeControlStr (Цвет $login: $colorStr)\nОтправьте эту ссылку-приглашение противнику:';
        }
    }

    public static function isHostingAChallengeText(challengeOwner:String, startSecs:Int, bonusSecs:Int, color:Null<String>):String
    {
        var timeControlStr = '${startSecs/60}+${bonusSecs/1}';
        var colorSuffix:String = color == null? "" : ", " + getColorName(PieceColor.createByName(color));
        var detailsStr = timeControlStr + colorSuffix;
        return switch Preferences.instance.language {
            case EN: '$challengeOwner is hosting a challenge ($detailsStr). First one to accept it will become an opponent\n';
            case RU: '$challengeOwner вызывает на бой ($detailsStr). Первый, кто примет вызов, станет противником\n';
        }
    }

    public static function getAnalysisTurnColorSelectLabel(color:PieceColor):String 
    {
		return switch Preferences.instance.language {
            case EN: color == White? "White to move" : "Black to move";
            case RU: color == White? "Ход белых" : "Ход черных";
        }
	}
}