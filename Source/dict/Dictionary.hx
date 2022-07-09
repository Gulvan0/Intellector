package dict;

class Dictionary 
{
    private static var order:Array<Language> = [EN, RU];

    private static var dict:Map<Phrase, Array<String>> = 
    [
        ANALYSIS_SET_POSITION_BTN_TOOLTIP => ["Set position", "Задать позицию"],
        ANALYSIS_SHARE_BTN_TOOLTIP => ["Share", "Поделиться"],
        ANALYSIS_OVERVIEW_TAB_NAME => ["Overview", "Обзор"],
        ANALYSIS_BRANCHING_TAB_NAME => ["Branches", "Ветви"],
        ANALYSIS_OPENINGS_TAB_NAME => ["Openings", "Дебюты"],
        ANALYSIS_OPENINGS_TEASER_TEXT => ["Coming soon", "Скоро"],
        ANALYSIS_CLEAR_BTN_TOOLTIP => ["Clear", "Очистить"],
        ANALYSIS_RESET_BTN_TOOLTIP => ["Reset", "Заново"],
        ANALYSIS_IMPORT_BTN_TOOLTIP => ["Import from SIP", "Импорт из SIP"],
        ANALYSIS_FLIP_BOARD_BTN_TOOLTIP => ["Flip board", "Перевернуть доску"],
        ANALYSIS_TO_STARTPOS_BTN_TOOLTIP => ["To starting position", "К начальной расстановке"],
        ANALYSIS_WHITE_TO_MOVE_OPTION_TEXT => ["White to Move", "Ход белых"],
        ANALYSIS_BLACK_TO_MOVE_OPTION_TEXT => ["Black to Move", "Ход черных"],
        ANALYSIS_APPLY_CHANGES_BTN_TEXT => ["Apply changes", "Применить изменения"],
        ANALYSIS_DISCARD_CHANGES_BTN_TEXT => ["Discard changes", "Отклонить изменения"],
        ANALYSIS_INPUT_SIP_PROMPT_TEXT => ["Input SIP", "Введите SIP"],
        ANALYSIS_INVALID_SIP_WARNING_TITLE => ["Warning: Invalid SIP", "Ошибка: Недопустимый SIP"],
        ANALYSIS_INVALID_SIP_WARNING_TEXT => ["The SIP specified is invalid", "Введенная вами строка не является допустимым SIP"],
        ANALYSIS_BRANCHING_HELP_LINK_TEXT => ["Branching Help", "Справка по дереву вариантов"],
        ANALYSIS_BRANCHING_HELP_DIALOG_TITLE => ["Branching Help", "Справка (дерево вариантов)"],
        ANALYSIS_BRANCHING_HELP_DIALOG_TEXT => ["Click on the nodes to switch to the corresponding branch.\nCtrl+Click on any node to remove it.\nUse your mouse wheel to scroll vertically.\nUse your mouse wheel while pressing Ctrl to scroll horizontally.\nUse your mouse wheel while pressing Shift to zoom in and out.", "Клик по любому узлу дерева позволяет переключиться на сооветствующую ветвь варианта.\nКлик с зажатой клавишей Ctrl по любому узлу дерева удаляет этот узел.\nИспользуйте колесико мыши для вертикальной прокрутки, а для прокрутки по горизонтали, зажмите Ctrl во время его вращения.\nПриближение/отдаление дерева вариантов осуществляется при помощи использования колесика мыши с зажатой клавишей Shift"],

        SHARE_DIALOG_TITLE  => ["Share", "Поделиться"],
        SHARE_POSITION_TAB_NAME  => ["Share Position", "Поделиться позицией"],
        SHARE_SIP_HEADER  => ["SIP", "SIP"],
        SHARE_IMAGE_HEADER  => ["Image", "Картинка"],
        SHARE_DOWNLOAD_PNG_BTN_TEXT  => ["Download PNG", "Скачать PNG"],
        SHARE_GAME_TAB_NAME  => ["Share Game", "Поделиться игрой"],
        SHARE_LINK_HEADER  => ["Link", "Ссылка"],
        SHARE_PIN_HEADER  => ["PIN", "PIN"],
        SHARE_ANIMATED_GIF_HEADER  => ["Animated GIF", "Анимированная GIF"],
        SHARE_EXPORT_AND_DOWNLOAD_BTN_TEXT  => ["Export & Download", "Скачать"],
        SHARE_EXPORT_TAB_NAME  => ["Export", "Экспорт"],
        SHARE_EXPORT_AS_STUDY_HEADER  => ["Export as Study", "Экспорт студии"],
        SHARE_NAME_PREFIX_LABEL  => ["Name: ", "Название: "],
        SHARE_STUDY_NAME_TEXTFIELD_PLACEHOLDER  => ["Enter study name...", "Название студии..."],
        SHARE_EXPORT_NEW_BTN_TEXT  => ["Create New Study", "Создать новую студию"],
        SHARE_OVERWRITE_BTN_TEXT_TEMPLATE  => ["Overwrite %name%", "Перезаписать %name%"],
        SHARE_EXPORT_AS_QUESTION_MARKS_TEASER  => ["Export as ???", "Экспорт ???"],
        SHARE_COMING_SOON  => ["Coming soon!", "Скоро!"],
        
        COPY_BTN_TOOLTIP  => ["Copy", "Копировать"],
        COPY_BTN_SUCCESS_TOOLTIP  => ["Copied!", "Скопировано!"],

        LIVE_SHARE_BTN_TOOLTIP => ["Share", "Поделиться"], 

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
        SPECTATOR_JOINED_MESSAGE => ["$0 is now spectating", "$0 стал наблюдателем"],
        SPECTATOR_LEFT_MESSAGE => ["$0 left", "$0 вышел"],
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
        RESIGN_BTN_ABORT_TOOLTIP => ["Abort", "Прервать"],
        REMATCH_BTN_TOOLTIP => ["Rematch", "Реванш"],
        EXPLORE_IN_ANALYSIS_BTN_TOOLTIP => ["Explore on analysis board", "На доску анализа"],
        ADD_TIME_BTN_TOOLTIP => ["Add time", "Добавить время"],
        OFFER_DRAW_BTN_TOOLTIP => ["Offer draw", "Ничья"],
        TAKEBACK_BTN_TOOLTIP => ["Takeback", "Запросить возврат хода"],
        CANCEL_DRAW_BTN_TOOLTIP => ["Cancel draw", "Отменить ничью"],
        CANCEL_TAKEBACK_BTN_TOOLTIP => ["Cancel takeback", "Отменить возврат хода"],
        RESIGN_BTN_TOOLTIP => ["Resign", "Сдаться"],
        CHANGE_ORIENTATION_BTN_TOOLTIP => ["Flip board", "Перевернуть доску"],
        RESIGN_CONFIRMATION_MESSAGE => ["Are you sure you want to resign?", "Вы уверены, что хотите сдаться?"],
        DRAW_QUESTION_TEXT => ["Accept draw?", "Принять ничью?"],
        TAKEBACK_QUESTION_TEXT => ["Accept takeback?", "Дать переходить?"],
        DRAW_OFFERED_MESSAGE => ["Draw offered", "Ничья предложена"],
        DRAW_CANCELLED_MESSAGE => ["Draw cancelled", "Предложение ничьи отменено"],
        DRAW_ACCEPTED_MESSAGE => ["Draw accepted", "Ничья принята"],
        DRAW_DECLINED_MESSAGE => ["Draw declined", "Ничья отклонена"],
        TAKEBACK_OFFERED_MESSAGE => ["Takeback offered", "Тейкбек предложен"],
        TAKEBACK_CANCELLED_MESSAGE => ["Takeback cancelled", "Запрос тейкбека отменен"],
        TAKEBACK_ACCEPTED_MESSAGE => ["Takeback accepted", "Тейкбек принят"],
        TAKEBACK_DECLINED_MESSAGE => ["Takeback declined", "Тейкбек отклонен"],
        OPPONENT_DISCONNECTED_MESSAGE => ["$0 disconnected", "$0 отключились"],
        OPPONENT_RECONNECTED_MESSAGE => ["$0 reconnected", "$0 переподключились"],
        GAME_OVER_MESSAGE_SUFFIX_WIN => [" won", " победили"],
        GAME_OVER_MESSAGE_SUFFIX_TIMEOUT => [" time out", " просрочили время"],
        GAME_OVER_MESSAGE_SUFFIX_RESIGN => [" resigned", " сдались"],
        GAME_OVER_MESSAGE_SUFFIX_DISCONNECT => [" abandoned", " покинули партию"],
        GAME_OVER_MESSAGE_DRAW => ["Game ended as a draw", "Игра окончена вничью"],
        GAME_OVER_MESSAGE_ABORT => ["Game aborted", "Игра прервана"],
        ABORT_CONFIRMATION_MESSAGE => ["Are you sure you want to abort the game?", "Вы уверены, что хотите прервать игру?"],
        OPEN_CHALLENGE_CANCEL_CONFIRMATION => ["Cancel challenge and return to the main menu?", "Отменить вызов и вернуться в главное меню?"],
        ENTER_PROFILE_OWNER => ["Enter the login of a profile owner", "Введите логин игрока, профиль которого вы хотите посетить"],
        INCOMING_CHALLENGE_TEXT => ["$0 wants to play with you ($1). Accept the challenge?", "$0 хочет с вами сыграть ($1). Принять вызов?"],
        LANGUAGE_NAME => ["English", "Русский"],
        SEND_CHALLENGE_RESULT_NOTFOUND => ["Callee not found", "Вызываемый игрок не найден"],
        ACCEPT_CHALLENGE_RESULT_CANCELLED => ["A challenge has been cancelled", "Оппонент отменил вызов"],
        ACCEPT_CHALLENGE_RESULT_OFFLINE => ["Caller is offline", "Оппонент не в сети"],
        ACCEPT_CHALLENGE_RESULT_BUSY => ["Caller is currently playing", "Оппонент в игре"],
        CORRESPONDENCE_TIME_CONTROL_NAME => ["Correspondence", "По переписке"],

        SESSION_CLOSED_ALERT_TITLE => ["Connection Closed", "Соединение закрыто"],
        SESSION_CLOSED_ALERT_TEXT => ["Connection was closed. Either you logged from another tab, browser or device or you were inactive for too long. Reload the page to reconnect", "Соединение было разорвано. Либо вы подключились из другой вкладки, из другого браузера или с другого устройства, либо же вы были неактивны слишком долго. Перезагрузите страницу для переподключения"],
        CLIPBOARD_ERROR_ALERT_TITLE => ["Clipboard Error", "Ошибка буфера обмена"],
        CLIPBOARD_ERROR_ALERT_TEXT => ["Failed to copy: $0", "Копирование не удалось: $0"],
    ];

    public static function getPhrase(phrase:Phrase, ?substitutions:Array<String>):String
    {
        var translation = chooseTranslation(dict.get(phrase));
        if (substitutions != null)
            for (i in 0...substitutions.length)
                translation = StringTools.replace(translation, '$' + i, substitutions[i]);
        return translation;
    }

    public static function chooseTranslation(translations:Array<String>):String
    {
        return translations[order.indexOf(Preferences.language.get())];
    }

    public static function getLanguageName(lang:Language)
    {
        return dict.get(LANGUAGE_NAME)[order.indexOf(lang)];
    }
}