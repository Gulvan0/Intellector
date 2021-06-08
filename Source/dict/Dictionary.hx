package dict;

import Figure.FigureColor;

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
        CHOOSE_TIME_CONTROL => ["Specify time control for your challenge", "Выберите контроль времени"],
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
        ENTER_SPECTATED => ["Enter the username of a player whose game you want to spectate", "За чьей игрой наблюдать?"],
        SETTINGS_MARKUP_TITLE => ["Markup: ", "Метки: "],
        SETTINGS_MARKUP_TYPE_NONE => ["None", "Нет"],
        SETTINGS_MARKUP_TYPE_SIDE => ["On the side", "Сбоку доски"],
        SETTINGS_MARKUP_TYPE_OVER => ["Overboard", "На доске"],
        SETTINGS_LANGUAGE_TITLE => ["Language: ", "Язык: "],
        SETTINGS_TITLE => ["Setings", "Настройки"],
        WIN_MESSAGE_PREAMBLE => ["You won", "Вы победили"],
        LOSS_MESSAGE_PREAMBLE => ["You lost", "Вы проиграли"],
        GAME_OVER_REASON_BREAKTHROUGH => [" by breakthrough.", " - Интеллектор добежал"],
        GAME_OVER_REASON_TIMEOUT => [" by timeout.", " по времени."],
        GAME_OVER_REASON_RESIGN => [" by resignation.", " (проигравший сдался)."],
        GAME_OVER_REASON_DISCONNECT => [". Opponent disconnected.", ". Оппонент покинул партию."],
        GAME_OVER_REASON_THREEFOLD => [" (Threefold repetition).", " (Тройное повторение)."],
        GAME_OVER_REASON_HUNDRED => [" (Hundred move rule).", " (Правило 100 ходов)."],
        GAME_OVER_REASON_AGREEMENT => [" (by agreement).", " (по взаимному согласию)."],
        GAME_OVER => ["Game over. ", "Игра окончена. "],
        GAME_ENDED => ["Game ended", "Игра окончена"],
        CONNECTION_LOST_ERROR => ["Connection lost", "Потеряно соединение"],
        CONNECTION_ERROR_OCCURED => ["Connection error occured: ", "Ошибка подключения: "],
        SPECTATION_ERROR_TITLE => ["Spectation error", "Ошибка наблюдения"],
        SPECTATION_ERROR_REASON_OFFLINE => ["Player is offline", "Игрок не в сети"],
        SPECTATION_ERROR_REASON_NOTINGAME => ["Player is not in game", "Игрок не в игре"],
        INCOMING_CHALLENGE_QUESTION => [" wants to play with you. Accept the challenge?", " хочет с вами сыграть. Принять вызов?"],
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
        RESOLUTION_HUNDRED => ["Draw by 100-move rule", "Ничья ввиду правила 100 ходов"],
        RESOLUTION_WINNER_POSTFIX => [" is victorious", " победил(а)"],
        WILL_BE_GUEST => ['You will be playing as guest', "Вы будете играть как гость"],
        JOINING_AS => ["You are joining the game as ", "Вы будете играть как "],
        OPENING_STARTING_POSITION => ["Starting position", "Начальная позиция"],
        OPEN_CHALLENGE_FIRST_TO_FOLLOW_NOTE => ['First one to follow the link will join the game', 'Первый, кто перейдет по ссылке, примет вызов']
    ];

    public static function getPhrase(phrase:Phrase):String
    {
        return dict.get(phrase)[order.indexOf(lang)];
    }

    public static function challengeByText(login:String, start:Int, bonus:Int):String
    {
        var timeControlStr = '${start/60}+$bonus';
        return switch lang {
            case EN: 'Challenge by $login\n$timeControlStr\nShare the link to invite your opponent:';
            case RU: 'Вызов $login\n$timeControlStr\nСсылка-приглашение:';
        }
    }

    public static function isHostingAChallengeText(data):String
    {
        var timeControlStr = '${data.startSecs/60}+${data.bonusSecs/1}';
        return switch lang {
            case EN: '${data.challenger} is hosting a challenge ($timeControlStr). First one to accept it will become an opponent\n';
            case RU: '${data.challenger} вызывает на бой ($timeControlStr). Первый, кто его примет, станет противником\n';
        }
    }

    public static function colorReferring(color:FigureColor):String
    {
        return switch lang {
            case EN: color == White? "White" : "Black";
            case RU: color == White? "Белые" : "Черные";
        } 
    }
}