package dict;

import gfx.components.gamefield.modules.GameInfoBox.Outcome;
import gfx.components.gamefield.modules.Field.Markup;
import gfx.screens.MainMenu.MainMenuButton;
import struct.PieceColor;

class Dictionary 
{
    public static var lang:Language = Language.EN;
    private static var order:Array<Language> = [EN, RU];

    private static var dict:Map<Phrase, Array<String>> = 
    [
        CHATBOX_MESSAGE_PLACEHOLDER => ["Message text...", "Сообщение..."],
        PROMOTION_DIALOG_QUESTION => ["Select a piece to which you want to promote", "Выберите фигуру, в которую хотите превратиться"],
        PROMOTION_DIALOG_TITLE => ["Promotion selection", "Превращение"],
        CHAMELEON_DIALOG_QUESTION => ["Morph into an eaten figure?", "Превратиться в съеденную фигуру?"],
        CHAMELEON_DIALOG_TITLE => ["Chameleon confirmation", "Хамелеон"],
        CHOOSE_TIME_CONTROL => ["Time control:", "Контроль времени:"],
        CHOOSE_COLOR => ["Color:", "Цвет:"],
        COLOR_RANDOM => ["Random", "Случайно"],
        CONFIRM => ["Confirm", "ОК"],
        CANCEL => ["Cancel", "Отмена"],
        CHALLENGE_PARAMS_TITLE => ["Challenge parameters", "Параметры вызова"],
        RETURN => ["Return", "Назад"],
        ANALYSIS_CLEAR => ["Clear", "Очистить"],
        ANALYSIS_RESET => ["Reset", "Сброс"],
        LOGIN_FIELD_TITLE => ["Login", "Логин"],
        PASSWORD_FIELD_TITLE => ["Password", "Пароль"],
        REMEMBER_ME_CHECKBOX_TITLE => ["Remember me", "Запомнить"],
        SIGN_IN_BTN => ["Sign In", "Войти"],
        REGISTER_BTN => ["Register", "Зарегистрироваться"],
        ALREADY_LOGGED => ["An user with this login is already online", "Пользователь с таким логином уже в сети"],
        INVALID_PASSWORD => ["Invalid login/password", "Неверный логин/пароль"],
        ALREADY_REGISTERED => ["An user with this login already exists", "Пользователь с таким логином уже существует"],
        SPECIFY_BOTH_REG_ERROR => ["You need to specify both the login and the password", "Введите логин и пароль"],
        SEND_CHALLENGE => ["Send challenge", "Отправить вызов"],
        ENTER_CALLEE => ["Enter the callee's username", "Кого вызвать?"],
        OPEN_CHALLENGE_BTN => ["Host open challenge", "Создать открытый вызов"],
        ANALYSIS_BTN => ["Analysis board", "Доска анализа"],
        ACCEPT_CHALLENGE => ["Accept challenge", "Принять вызов"],
        SETTINGS_BTN => ["Settings", "Настройки"],
        LOG_OUT_BTN => ["Log out", "Выйти"],
        SPECTATE_BTN => ["Spectate", "Наблюдать"],
        PROFILE_BTN => ["Visit player's profile", "Открыть профиль игрока"],
        ENTER_SPECTATED => ["Enter the username of a player whose game you want to spectate", "За чьей игрой наблюдать?"],
        SETTINGS_MARKUP_TITLE => ["Markup: ", "Метки: "],
        SETTINGS_MARKUP_TYPE_NONE => ["None", "Нет"],
        SETTINGS_MARKUP_TYPE_SIDE => ["On the side", "Сбоку доски"],
        SETTINGS_MARKUP_TYPE_OVER => ["Overboard", "На доске"],
        SETTINGS_LANGUAGE_TITLE => ["Language: ", "Язык: "],
        SETTINGS_TITLE => ["Setings", "Настройки"],
        WIN_MESSAGE_PREAMBLE => ["You won", "Вы победили"],
        LOSS_MESSAGE_PREAMBLE => ["You lost", "Вы проиграли"],
        GAME_OVER_REASON_MATE => [".", "."],
        GAME_OVER_REASON_BREAKTHROUGH => [" by breakthrough.", " - Интеллектор добежал"],
        GAME_OVER_REASON_TIMEOUT => [" by timeout.", " по времени."],
        GAME_OVER_REASON_RESIGN => [" by resignation.", " (проигравший сдался)."],
        GAME_OVER_REASON_DISCONNECT => [". Opponent disconnected.", ". Оппонент покинул партию."],
        GAME_OVER_REASON_THREEFOLD => [" (Threefold repetition).", " (Тройное повторение)."],
        GAME_OVER_REASON_HUNDRED => [" (Hundred move rule).", " (Правило 100 ходов)."],
        GAME_OVER_REASON_AGREEMENT => [" (by agreement).", " (по взаимному согласию)."],
        GAME_OVER_REASON_ABORT => ["Game aborted", "Игра прервана"],
        GAME_OVER => ["Game over. ", "Игра окончена. "],
        GAME_ENDED => ["Game ended", "Игра окончена"],
        CONNECTION_LOST_ERROR => ["Connection lost", "Потеряно соединение"],
        CONNECTION_ERROR_OCCURED => ["Connection error occured: ", "Ошибка подключения: "],
        SPECTATION_ERROR_TITLE => ["Spectation error", "Ошибка наблюдения"],
        SPECTATION_ERROR_REASON_OFFLINE => ["Player is offline", "Игрок не в сети"],
        SPECTATION_ERROR_REASON_NOTINGAME => ["Player is not in game", "Игрок не в игре"],
        INCOMING_CHALLENGE_TITLE => ["Incoming challenge", "Входящий вызов"],
        SEND_CHALLENGE_RESULT_SUCCESS => ["Challenge sent to ", "Вызов отправлен игроку "],
        SEND_CHALLENGE_RESULT_DECLINED => [" has declined your challenge", " отклонил(а) ваш вызов"],
        SEND_CHALLENGE_RESULT_SAME => ["You can't challenge yourself", "Вы не можете отправлять вызов самому себе"],
        SEND_CHALLENGE_RESULT_REPEATED => ["You have already sent a challenge to this player", "Вы уже отправили этому игроку вызов"],
        SEND_CHALLENGE_RESULT_OFFLINE => ["Callee is offline", "Вызванный игрок не в сети"],
        SEND_CHALLENGE_RESULT_BUSY => ["Callee is currently playing", "Вызванный игрок в игре"],
        SEND_CHALLENGE_RESULT_DECLINED_TITLE => ["Challenge declined", "Вызов отклонен"],
        SEND_CHALLENGE_RESULT_ERROR_TITLE => ["Challenge error", "Ошибка вызова"],
        SEND_CHALLENGE_RESULT_SUCCESS_TITLE => ["Success", "Успех"],
        SPECTATOR_JOINED_MESSAGE => [" is now spectating", " стал наблюдателем"],
        SPECTATOR_LEFT_MESSAGE => [" left", " вышел"],
        RESOLUTION_NONE => ["Game is in progress", "Идет игра"],
        RESOLUTION_MATE => ["Mate", "Мат"],
        RESOLUTION_BREAKTHROUGH => ["Breakthrough", "Добегание"],
        RESOLUTION_RESIGN => [" resigned", " сдались"],
        RESOLUTION_DISCONNECT => [" disconnected", " покинули игру"],
        RESOLUTION_AGREEMENT => ["Draw by agreement", "Ничья по согласию"],
        RESOLUTION_REPETITON => ["Draw by repetition", "Ничья по троекратному повторению"],
        RESOLUTION_ABORT => ["Game aborted", "Игра прервана"],
        RESOLUTION_HUNDRED => ["Draw by 100-move rule", "Ничья ввиду правила 100 ходов"],
        RESOLUTION_TIMEOUT => ["Timeout", "Законичилось время"],
        RESOLUTION_WINNER_POSTFIX => [" is victorious", " победили"],
        WILL_BE_GUEST => ['You will be playing as guest', "Вы будете играть как гость"],
        JOINING_AS => ["You are joining the game as ", "Вы будете играть как "],
        OPENING_STARTING_POSITION => ["Starting position", "Начальная позиция"],
        OPEN_CHALLENGE_FIRST_TO_FOLLOW_NOTE => ['First one to follow the link will join the game', 'Первый, кто перейдет по ссылке, примет вызов'],
        RESIGN_BTN_TEXT => ["Resign", "Сдаться"],
        RESIGN_CONFIRMATION_MESSAGE => ["Are you sure you want to resign?", "Вы уверены, что хотите сдаться?"],
        OFFER_DRAW_BTN_TEXT => ["Offer draw", "Ничья"],
        TAKEBACK_BTN_TEXT => ["Takeback", "Запросить отмену хода"],
        DRAW_QUESTION_TEXT => ["Accept draw?", "Принять ничью?"],
        TAKEBACK_QUESTION_TEXT => ["Accept takeback?", "Разрешить переходить?"],
        DRAW_OFFERED_MESSAGE => ["Draw offered", "Ничья предложена"],
        DRAW_CANCELLED_MESSAGE => ["Draw cancelled", "Предложение ничьи отменено"],
        DRAW_ACCEPTED_MESSAGE => ["Draw accepted", "Ничья принята"],
        DRAW_DECLINED_MESSAGE => ["Draw declined", "Ничья отклонена"],
        TAKEBACK_OFFERED_MESSAGE => ["Takeback offered", "Тейкбек предложен"],
        TAKEBACK_CANCELLED_MESSAGE => ["Takeback cancelled", "Запрос тейкбека отменен"],
        TAKEBACK_ACCEPTED_MESSAGE => ["Takeback accepted", "Тейкбек принят"],
        TAKEBACK_DECLINED_MESSAGE => ["Takeback declined", "Тейкбек отклонен"],
        CANCEL_DRAW_BTN_TEXT => ["Cancel draw", "Отменить ничью"],
        CANCEL_TAKEBACK_BTN_TEXT => ["Cancel takeback", "Отменить тейкбек"],
        OPPONENT_DISCONNECTED_MESSAGE => [" disconnected", " отключились"],
        OPPONENT_RECONNECTED_MESSAGE => [" reconnected", " переподключились"],
        ANALYSIS_ANALYZE_WHITE => ["Analyze as white", "Анализ за белых"],
        ANALYSIS_ANALYZE_BLACK => ["Analyze as black", "Анализ за черных"],
        GAME_OVER_MESSAGE_SUFFIX_WIN => [" won", " победили"],
        GAME_OVER_MESSAGE_SUFFIX_TIMEOUT => [" time out", " просрочили время"],
        GAME_OVER_MESSAGE_SUFFIX_RESIGN => [" resigned", " сдались"],
        GAME_OVER_MESSAGE_SUFFIX_DISCONNECT => [" abandoned", " покинули партию"],
        GAME_OVER_MESSAGE_DRAW => ["Game ended as a draw", "Игра окончена вничью"],
        GAME_OVER_MESSAGE_ABORT => ["Game aborted", "Игра прервана"],
        RESIGN_BTN_ABORT_TEXT => ["Abort", "Прервать"],
        ABORT_CONFIRMATION_MESSAGE => ["Are you sure you want to abort the game?", "Вы уверены, что хотите прервать игру?"],
        OPEN_CHALLENGE_CANCEL_CONFIRMATION => ["Cancel challenge and return to the main menu?", "Отменить вызов и вернуться в главное меню?"],
        ENTER_PROFILE_OWNER => ["Enter the login of a profile owner", "Введите логин игрока, профиль которого вы хотите посетить"],
        ANALYSIS_APPLY => ["Apply", "ОК"],
        ANALYSIS_APPLY_CHANGES => ["Apply changes", "Применить изменения"],
        ANALYSIS_DISCARD_CHANGES => ["Discard changes", "Отклонить изменения"],
        ANALYSIS_EXPORT_SIP => ["Export SIP", "Экспорт SIP"],
        ANALYSIS_SET_POSITION => ["Set position", "Задать позицию"],
        ANALYSIS_OVERVIEW_TAB_NAME => ["Overview", "Обзор"],
        ANALYSIS_BRANCHES_TAB_NAME => ["Branches", "Ветви"],
        ANALYSIS_OPENINGS_TAB_NAME => ["Openings", "Дебюты"],
        ANALYSIS_OPENINGS_TEASER_TEXT => ["Coming soon", "Скоро"],
        ANALYSIS_EXPORTED_SIP_MESSAGE => ["SIP:", "SIP:"]
    ];

    public static function getPhrase(phrase:Phrase):String
    {
        return dict.get(phrase)[order.indexOf(lang)];
    }

    public static function getIncomingChallengeText(data):String
    {
        var timeControlStr = '${data.startSecs/60}+${data.bonusSecs/1}';
        var colorSuffix:String = data.color == null? "" : ", " + getColorName(PieceColor.createByName(data.color));
        var detailsStr = timeControlStr + colorSuffix;
        return switch lang 
        {
            case EN: '${data.caller} wants to play with you ($detailsStr). Accept the challenge?';
            case RU: '${data.caller} хочет с вами сыграть ($detailsStr). Принять вызов?';
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

    public static function getMatchlistResultText(winner:Null<PieceColor>, outcome:Null<Outcome>) 
    {
        return getMatchlistWinnerText(winner) + " (" + getMatchlistOutcomeText(outcome) + ")";
    }

    private static function getMatchlistWinnerText(color:Null<PieceColor>) 
    {
        if (color == null)
            return switch lang 
            {
                case EN: "Draw";
                case RU: "Ничья";
            }
        else
            return getColorName(color) + switch lang 
            {
                case EN: " won";
                case RU: " победили";
            }
    }

    private static function getMatchlistOutcomeText(outcome:Null<Outcome>) 
    {
        switch lang 
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

    public static function getColorName(color:PieceColor) 
    {
        return switch lang 
        {
            case EN: color.getName();
            case RU: color == White? "Белые" : "Черные";
        }
    }

    public static function getGameOverChatMessage(winnerColor:Null<PieceColor>, reason:String):String
    {
        return switch reason
		{
			case 'mate': getColorName(winnerColor) + Dictionary.getPhrase(GAME_OVER_MESSAGE_SUFFIX_WIN);
			case 'breakthrough': getColorName(winnerColor) + Dictionary.getPhrase(GAME_OVER_MESSAGE_SUFFIX_WIN);
			case 'timeout': getColorName(opposite(winnerColor)) + Dictionary.getPhrase(GAME_OVER_MESSAGE_SUFFIX_TIMEOUT);
			case 'resignation': getColorName(opposite(winnerColor)) + Dictionary.getPhrase(GAME_OVER_MESSAGE_SUFFIX_RESIGN);
            case 'abandon': getColorName(opposite(winnerColor)) + Dictionary.getPhrase(GAME_OVER_MESSAGE_SUFFIX_DISCONNECT);
            case 'abort': Dictionary.getPhrase(GAME_OVER_MESSAGE_ABORT);
			default: Dictionary.getPhrase(GAME_OVER_MESSAGE_DRAW);
        };
    }

    public static function challengeByText(login:String, start:Int, bonus:Int, color:Null<PieceColor>):String
    {
        var timeControlStr = '${start/60}+$bonus';
        var colorStr:String = color == null? getPhrase(COLOR_RANDOM) : getColorName(color);
        return switch lang {
            case EN: 'Challenge by $login\n$timeControlStr ($login plays as $colorStr)\nShare the link to invite your opponent:';
            case RU: 'Вызов $login\n$timeControlStr (Цвет $login: $colorStr)\nОтправьте эту ссылку-приглашение противнику:';
        }
    }

    public static function isHostingAChallengeText(data):String
    {
        var timeControlStr = '${data.startSecs/60}+${data.bonusSecs/1}';
        var colorSuffix:String = data.color == null? "" : ", " + getColorName(PieceColor.createByName(data.color));
        var detailsStr = timeControlStr + colorSuffix;
        return switch lang {
            case EN: '${data.challenger} is hosting a challenge ($detailsStr). First one to accept it will become an opponent\n';
            case RU: '${data.challenger} вызывает на бой ($detailsStr). Первый, кто примет вызов, станет противником\n';
        }
    }

    public static function getAnalysisTurnColorSelectLabel(color:PieceColor):String 
    {
		return switch lang {
            case EN: color == White? "White to move" : "Black to move";
            case RU: color == White? "Ход белых" : "Ход черных";
        }
	}
}