package dict;

class Dictionary 
{
    private static var order:Array<Language> = [EN, RU];

    private static var dict:Map<Phrase, Array<String>> = 
    [
        LANGUAGE_NAME => ["English", "Русский"],

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
        ANALYSIS_BRANCHING_HELP_DIALOG_TEXT => ["<p><u><b>General</b></u></p><br><p><em>Use branching tab to navigate between different variations of the study. You can change the mode in settings.</em></p><br><p><b>LMB (Click):</b> Switch to branch</p><br><p><b>CTRL + LMB (Click):</b> Remove branch</p><br><p><b>Mouse wheel:</b> Scroll vertically</p><br><p><b>SHIFT + Mouse wheel:</b> Scroll horizontally</p><br><p>Alternatively, <b>Click &amp; Hold LMB</b> while moving the mouse to drag</p><br><p><u><b>Tree Mode</b></u></p><br><p><b>CTRL + Mouse wheel:</b> Zoom in / out</p>", ""],

        SHARE_DIALOG_TITLE => ["Share", "Поделиться"],
        SHARE_POSITION_TAB_NAME => ["Share Position", "Поделиться позицией"],
        SHARE_SIP_HEADER => ["SIP", "SIP"],
        SHARE_IMAGE_HEADER => ["Image", "Картинка"],
        SHARE_DOWNLOAD_PNG_BTN_TEXT => ["Download PNG", "Скачать PNG"],
        SHARE_DOWNLOAD_PNG_MARKUP_CHECKBOX_TEXT => ["Add Markup", "Добавить метки"],
        SHARE_DOWNLOAD_PNG_DIMENSIONS_LABEL_TEXT => ["Dimensions: ", "Размер: "],
        SHARE_DOWNLOAD_PNG_KEEP_RATIO_CHECKBOX_TEXT => ["Keep Aspect Ratio", "Сохранять пропорции"],
        SHARE_DOWNLOAD_PNG_BGCOLOR_LABEL_TEXT => ["Background Color: ", "Цвет фона: "],
        SHARE_DOWNLOAD_PNG_TRANSPARENT_BG_CHECKBOX_TEXT => ["Transparent Background", "Прозрачный фон"],
        SHARE_GAME_TAB_NAME => ["Share Game", "Поделиться игрой"],
        SHARE_LINK_HEADER => ["Link", "Ссылка"],
        SHARE_PIN_HEADER => ["PIN", "PIN"],
        SHARE_ANIMATED_GIF_HEADER => ["Animated GIF", "Анимированная GIF"],
        SHARE_DOWNLOAD_GIF_WIDTH_LABEL_TEXT => ["Width: ", "Ширина: "],
        SHARE_DOWNLOAD_GIF_INTERVAL_LABEL_TEXT => ["Interval (ms): ", "Интервал (мс): "],
        SHARE_EXPORT_AND_DOWNLOAD_BTN_TEXT => ["Export & Download", "Скачать"],
        SHARE_EXPORT_TAB_NAME => ["Export", "Экспорт"],
        SHARE_EXPORT_AS_STUDY_HEADER => ["Export as Study", "Экспорт студии"],
        SHARE_NAME_PREFIX_LABEL => ["Name: ", "Название: "],
        SHARE_STUDY_NAME_TEXTFIELD_PLACEHOLDER => ["Enter study name...", "Название студии..."],
        SHARE_EXPORT_NEW_BTN_TEXT => ["Create New Study", "Создать новую студию"],
        SHARE_OVERWRITE_BTN_TEXT_TEMPLATE => ["Overwrite %name%", "Перезаписать %name%"],
        SHARE_EXPORT_AS_QUESTION_MARKS_TEASER => ["Export as ???", "Экспорт ???"],
        SHARE_COMING_SOON => ["Coming soon!", "Скоро!"],
        
        COPY_BTN_TOOLTIP => ["Copy", "Копировать"],
        COPY_BTN_SUCCESS_TOOLTIP => ["Copied!", "Скопировано!"],

        LIVE_SHARE_BTN_TOOLTIP => ["Share", "Поделиться"], 

        OPENJOIN_CHALLENGE_BY_HEADER => ["Challenge by $0", "Вызов $0"],
        OPENJOIN_COLOR_WHITE_OWNER => ["$0 will play as White", "$0 играет белыми"],
        OPENJOIN_COLOR_BLACK_OWNER => ["$0 will play as Black", "$0 играет черными"],
        OPENJOIN_COLOR_RANDOM => ["Random color", "Случайный цвет"],
        OPENJOIN_RATED => ["Rated", "Рейтинговая"],
        OPENJOIN_UNRATED => ["Unrated", "Товарищеская"],
        OPENJOIN_ACCEPT_BTN_TEXT => ["Accept Challenge", "Принять вызов"],

        MENUBAR_PLAY_MENU_TITLE => ["Play", "Играть"],
        MENUBAR_PLAY_MENU_CREATE_GAME_ITEM => ["Create Game", "Создать игру"],
        MENUBAR_PLAY_MENU_OPEN_CHALLENGES_ITEM => ["Open Challenges", "Открытые вызовы"],
        
        MENUBAR_SPECTATE_MENU_TITLE => ["Spectate", "Смотреть"],
        MENUBAR_SPECTATE_MENU_CURRENT_GAMES_ITEM => ["Current Games", "Текущие партии"],
        MENUBAR_SPECTATE_MENU_FOLLOW_PLAYER_ITEM => ["Follow Player", "Наблюдать за игроком"],
        
        MENUBAR_LEARN_MENU_TITLE => ["Learn", "Учёба"],
        MENUBAR_LEARN_MENU_ANALYSIS_BOARD_ITEM => ["Analysis Board", "Доска анализа"],
        
        MENUBAR_SOCIAL_MENU_TITLE => ["Social", "Сообщество"],
        MENUBAR_SOCIAL_MENU_PLAYER_PROFILE_ITEM => ["Player Profile", "Профиль игрока"],

        MENUBAR_ACCOUNT_MENU_LOGIN_ITEM => ["Log In", "Войти"],
        MENUBAR_ACCOUNT_MENU_MY_PROFILE_ITEM => ["My Profile", "Мой профиль"],
        MENUBAR_ACCOUNT_MENU_SETTINGS_ITEM => ["Settings", "Настройки"],
        MENUBAR_ACCOUNT_MENU_LOGOUT_ITEM => ["Log Out", "Выйти"],
        MENUBAR_ACCOUNT_MENU_GUEST_DISPLAY_NAME => ["Guest", "Гость"],

        CHANGELOG_DIALOG_TITLE => ["Changelog", "Список изменений"],

        LOGIN_DIALOG_TITLE => ["Authorization", "Авторизация"],
        LOGIN_LOG_IN_MODE_TITLE => ["Log In", "Вход"],
        LOGIN_REGISTER_MODE_TITLE => ["Sign Up", "Регистрация"],
        LOGIN_LOGIN_FIELD_NAME => ["Login", "Логин"],
        LOGIN_PASSWORD_FIELD_NAME => ["Password", "Пароль"],
        LOGIN_REPEAT_PASSWORD_FIELD_NAME => ["Repeat password", "Повторите пароль"],
        LOGIN_REMEMBER_ME => ["Remember me", "Запомнить"],
        LOGIN_REMAIN_LOGGED => ["Stay logged in", "Оставаться в сети"],

        LOGIN_WARNING_MESSAGEBOX_TITLE => ["Authorization failed", "Ошибка авторизации"],
        LOGIN_INVALID_PASSWORD_WARNING_TEXT => ["Invalid login or password", "Неверный логин или пароль"],
        LOGIN_PASSWORDS_DO_NOT_MATCH => ["Passwords do not match", "Введенные пароли не совпадают"],
        LOGIN_ALREADY_REGISTERED_WARNING_TEXT => ["An user with this login already exists", "Пользователь с таким логином уже существует"],
        LOGIN_LOGIN_NOT_SPECIFIED_WARNING_TEXT => ["Login is not specified!", "Не указан логин!"],
        LOGIN_PASSWORD_NOT_SPECIFIED_WARNING_TEXT => ["Password is not specified!", "Не указан пароль!"],
        LOGIN_REPEATED_PASSWORD_NOT_SPECIFIED_WARNING_TEXT => ["\"Repeat Password\" field is empty!", "Поле \"Повторите пароль\" не заполнено!"],
        LOGIN_BAD_LOGIN_LENGTH_WARNING_TEXT => ["Login must contain between 2 and 16 characters", "Длина логина должна быть в диапазоне 2-16 символов"],
        LOGIN_BAD_PASSWORD_LENGTH_WARNING_TEXT => ["Password must contain at least 6 characters", "Длина пароля должна составлять не менее 6 символов"],

        SETTINGS_DIALOG_TITLE => ["Settings", "Настройки"],
        SETTINGS_GENERAL_TAB_TITLE => ["General", "Основные"],
        SETTINGS_APPEARANCE_TAB_TITLE => ["Appearance", "Внешний вид"],
        SETTINGS_CONTROLS_TAB_TITLE => ["Controls", "Управление"],
        SETTINGS_INTEGRATIONS_TAB_TITLE => ["Integrations", "Интеграции"],

        SETTINGS_LANGUAGE_OPTION_NAME => ["Language", "Язык"],
        SETTINGS_MARKUP_OPTION_NAME => ["Coordinates", "Координаты"],
        SETTINGS_PREMOVES_OPTION_NAME => ["Premoves", "Предходы"],
        SETTINGS_BRANCHING_TYPE_OPTION_NAME => ["Branching mode", "Вид ветвей"],
        SETTINGS_BRANCHING_SHOW_TURN_COLOR_OPTION_NAME => ["Display turn color in Tree mode", "Отображать цвет хода в режиме Дерева"],
        SETTINGS_SILENT_CHALLENGES_OPTION_NAME => ["Ignore incoming challenges", "Не уведомлять о входящих вызовах"],

        SETTINGS_MARKUP_ALL_OPTION_VALUE => ["All", "Все"],
        SETTINGS_MARKUP_LETTERS_OPTION_VALUE => ["Files only", "Только вертикали"],
        SETTINGS_MARKUP_NONE_OPTION_VALUE => ["None", "Нет"],

        SETTINGS_BRANCHING_TYPE_TREE_OPTION_VALUE => ["Tree", "Дерево"],
        SETTINGS_BRANCHING_TYPE_OUTLINE_OPTION_VALUE => ["Outline", "Список"],
        SETTINGS_BRANCHING_TYPE_PLAIN_OPTION_VALUE => ["Plain text", "Текст"],

        SETTINGS_DISABLED_OPTION_VALUE => ["Disabled", "Нет"],
        SETTINGS_ENABLED_OPTION_VALUE => ["Enabled", "Да"],

        FOLLOWED_PLAYER_LABEL_GAMEINFOBOX_TOOLTIP => ["You follow this player. Each time he/she starts a new game, you'll be automatically redirected to watch it. To unfollow, simply leave this screen.", "Вы наблюдаете за этим игроком. Если игрок начнет новую игру, вы автоматически последуете за ним. Чтобы прекратить наблюдение, просто покиньте этот экран"],

        MAIN_MENU_CREATE_GAME_BTN_TEXT => ["Create Game", "Создать игру"],
        READ_FULL_CHANGELOG_TOOLTIP => ["Read full changelog", "Полный список изменений"],

        TABLEVIEW_RELOAD_BTN_TEXT => ["Reload", "Обновить"],
        TABLEVIEW_MODE_COLUMN_NAME => ["Mode", "Режим"],
        TABLEVIEW_TIME_COLUMN_NAME => ["Time", "Контроль"],
        TABLEVIEW_PLAYER_COLUMN_NAME => ["Player", "Игрок"],
        TABLEVIEW_PLAYERS_COLUMN_NAME => ["Players", "Игроки"],
        TABLEVIEW_BRACKET_COLUMN_NAME => ["Bracket", "Тип"],
        TABLEVIEW_BRACKET_RANKED(false) => ["Rated", "На рейтинг"],
        TABLEVIEW_BRACKET_RANKED(true) => ["Unrated", "Товарищеская"],

        CURRENT_GAMES_TABLE_HEADER => ["Now Playing", "Текущие игры"],
        PAST_GAMES_TABLE_HEADER => ["Recent Games", "Недавние партии"],
        OPEN_CHALLENGES_TABLE_HEADER => ["Open Challenges", "Открытые вызовы"],

        CHALLENGE_COLOR_ICON_TOOLTIP(null) => ["Your color will be selected randomly", "Цвет будет выбран случайным образом"],
        CHALLENGE_COLOR_ICON_TOOLTIP(White) => ["You will play as White", "Вы будете играть за белых"],
        CHALLENGE_COLOR_ICON_TOOLTIP(Black) => ["You will play as Black", "Вы будете играть за черных"],

        GAME_CHATBOX_GAME_OVER_MESSAGE(Mate, White) => ["White won", "Белые победили"],
        GAME_CHATBOX_GAME_OVER_MESSAGE(Breakthrough, White) => ["White won", "Белые победили"],
        GAME_CHATBOX_GAME_OVER_MESSAGE(Timeout, White) => ["Black lost on time", "Черные просрочили время"],
        GAME_CHATBOX_GAME_OVER_MESSAGE(Resign, White) => ["Black resigned", "Черные сдались"],
        GAME_CHATBOX_GAME_OVER_MESSAGE(Abandon, White) => ["Black disconnected", "Черные покинули игру"],
        GAME_CHATBOX_GAME_OVER_MESSAGE(Mate, Black) => ["Black won", "Черные победили"],
        GAME_CHATBOX_GAME_OVER_MESSAGE(Breakthrough, Black) => ["Black won", "Черные победили"],
        GAME_CHATBOX_GAME_OVER_MESSAGE(Timeout, Black) => ["White lost on time", "Белые просрочили время"],
        GAME_CHATBOX_GAME_OVER_MESSAGE(Resign, Black) => ["White resigned", "Белые сдались"],
        GAME_CHATBOX_GAME_OVER_MESSAGE(Abandon, Black) => ["White disconnected", "Белые покинули игру"],
        GAME_CHATBOX_GAME_OVER_MESSAGE(DrawAgreement, null) => ["Game ended with a draw (mutual agreement)", "Игра окончена вничью (по договоренности)"],
        GAME_CHATBOX_GAME_OVER_MESSAGE(Repetition, null) => ["Game ended with a draw (threefold repetition)", "Игра окончена вничью (по троекратному повторению)"],
        GAME_CHATBOX_GAME_OVER_MESSAGE(NoProgress, null) => ["Game ended with a draw (sixty-move rule)", "Игра окончена вничью (по правилу 60 ходов)"],
        GAME_CHATBOX_GAME_OVER_MESSAGE(Abort, null) => ["Game aborted", "Игра прервана"],

        GAME_RESOLUTION_GAME_IN_PROGRESS => ["Game is in progress", "Идет игра"],
        GAME_RESOLUTION_OUTCOME_SENTENCE(Mate, White) => ["Fatum", "Фатум"],
        GAME_RESOLUTION_OUTCOME_SENTENCE(Breakthrough, White) => ["Breakthrough", "Прорыв"],
        GAME_RESOLUTION_OUTCOME_SENTENCE(Timeout, White) => ["Black lost on time", "Черные просрочили время"],
        GAME_RESOLUTION_OUTCOME_SENTENCE(Resign, White) => ["Black resigned", "Черные сдались"],
        GAME_RESOLUTION_OUTCOME_SENTENCE(Abandon, White) => ["Black disconnected", "Черные покинули игру"],
        GAME_RESOLUTION_OUTCOME_SENTENCE(Mate, Black) => ["Fatum", "Фатум"],
        GAME_RESOLUTION_OUTCOME_SENTENCE(Breakthrough, Black) => ["Breakthrough", "Прорыв"],
        GAME_RESOLUTION_OUTCOME_SENTENCE(Timeout, Black) => ["White lost on time", "Белые просрочили время"],
        GAME_RESOLUTION_OUTCOME_SENTENCE(Resign, Black) => ["White resigned", "Белые сдались"],
        GAME_RESOLUTION_OUTCOME_SENTENCE(Abandon, Black) => ["White disconnected", "Белые покинули игру"],
        GAME_RESOLUTION_OUTCOME_SENTENCE(DrawAgreement, null) => ["Draw by agreement", "Ничья по согласию"],
        GAME_RESOLUTION_OUTCOME_SENTENCE(Repetition, null) => ["Draw by repetition", "Ничья по троекратному повторению"],
        GAME_RESOLUTION_OUTCOME_SENTENCE(Abort, null) => ["Game aborted", "Игра прервана"],
        GAME_RESOLUTION_OUTCOME_SENTENCE(NoProgress, null) => ["Draw by sixty-move rule", "Ничья по правилу 60 ходов"],
        GAME_RESOLUTION_WINNER_SENTENCE(White) => ["White is victorious", "Белые победили"],
        GAME_RESOLUTION_WINNER_SENTENCE(Black) => ["Black is victorious", "Черные победили"],

        GAME_ENDED_DIALOG_TITLE => ["Game over", "Игра окончена"],
        GAME_ENDED_PLAYER_DIALOG_MESSAGE(Mate, true) => ["Your opponent's Intellector has been captured. You won!", "Интеллектор противника пал. Вы победили!"],
        GAME_ENDED_PLAYER_DIALOG_MESSAGE(Mate, false) => ["Your Intellector has been captured. You lost.", "Ваш Интеллектор пал. Вы проиграли."],
        GAME_ENDED_PLAYER_DIALOG_MESSAGE(Breakthrough, true) => ["Your Intellector has reached the last rank. You won!", "Ваш Интеллектор достиг последней горизонтали. Вы победили!"],
        GAME_ENDED_PLAYER_DIALOG_MESSAGE(Breakthrough, false) => ["Your opponent's Intellector has reached the last rank. You lost.", "Вражеский Интеллектор достиг последней горизонтали. Вы проиграли."],
        GAME_ENDED_PLAYER_DIALOG_MESSAGE(Timeout, true) => ["Your opponent has run out of time. You won!", "У вашего противника закончилось время. Вы победили!"],
        GAME_ENDED_PLAYER_DIALOG_MESSAGE(Timeout, false) => ["You lost on time.", "У вас закончилось время. Вы проиграли."],
        GAME_ENDED_PLAYER_DIALOG_MESSAGE(Resign, true) => ["Your opponent has resigned. You won!", "Ваш противник сдался. Вы победили!"],
        GAME_ENDED_PLAYER_DIALOG_MESSAGE(Resign, false) => ["You lost by resignation.", "Вы сдались; в игре засчитано поражение"],
        GAME_ENDED_PLAYER_DIALOG_MESSAGE(Abandon, true) => ["Your opponent has abandoned the game. You won!", "Ваш противник покинул партию. Вы победили!"],
        GAME_ENDED_PLAYER_DIALOG_MESSAGE(Abandon, false) => ["You lost (game abandoned).", "Игра покинута. Вы проиграли."],
        GAME_ENDED_SPECTATOR_DIALOG_MESSAGE(Mate) => ["$1's Intellector has been captured. $0 won.", "Интеллектор игрока $1 повержен. Победитель: $0."],
        GAME_ENDED_SPECTATOR_DIALOG_MESSAGE(Breakthrough) => ["$0's Intellector has reached the last rank. $0 won.", "Интеллектор игрока $0 достиг последней горизонтали. Победитель: $0."],
        GAME_ENDED_SPECTATOR_DIALOG_MESSAGE(Timeout) => ["$1 has lost on time. $0 won.", "Игрок $1 просрочил время. Победитель: $0."],
        GAME_ENDED_SPECTATOR_DIALOG_MESSAGE(Resign) => ["$1 has resigned. $0 won.", "Игрок $1 сдался. Победитель: $0."],
        GAME_ENDED_SPECTATOR_DIALOG_MESSAGE(Abandon) => ["$1 has left the game. $0 won.", "Игрок $1 покинул партию. Победитель: $0."],
        GAME_ENDED_DRAW_DIALOG_MESSAGE(DrawAgreement) => ["Game has ended up in a draw. Reason: mutual agreement.", "Игра завершена вничью. Причина: взаимное согласие"],
        GAME_ENDED_DRAW_DIALOG_MESSAGE(Repetition) => ["Game has ended up in a draw. Reason: threefold repetition.", "Игра завершена вничью. Причина: троекратное повторение"],
        GAME_ENDED_DRAW_DIALOG_MESSAGE(NoProgress) => ["Game has ended up in a draw. Reason: sixty-move rule.", "Игра завершена вничью. Причина: правило 60 ходов"],
        GAME_ENDED_DRAW_DIALOG_MESSAGE(Abort) => ["Game aborted.", "Игра прервана."],

        INPUT_PLAYER_LOGIN => ["Input player's username", "Введите ник игрока"],

        REQUESTS_ERROR_DIALOG_TITLE => ["Error", "Ошибка"],
        REQUESTS_ERROR_CHALLENGE_NOT_FOUND => ["Challenge not found", "Вызов не найден"],
        REQUESTS_ERROR_PLAYER_NOT_FOUND => ["Player not found", "Игрок не найден"],
        REQUESTS_ERROR_STUDY_NOT_FOUND => ["Study not found", "Студия не найдена"],
        REQUESTS_ERROR_PLAYER_OFFLINE => ["This player is offline", "Игрок не в сети"],
        REQUESTS_ERROR_PLAYER_NOT_IN_GAME => ["This player is not in the game", "В настоящий момент игрок не участвует в партии"],

        TURN_COLOR(White) => ["White to move", "Ход белых"],
        TURN_COLOR(Black) => ["Black to move", "Ход черных"],

        CUSTOM_STARTING_POSITION => ["Custom starting position", "Нестандартная начальная расстановка"],

        CHATBOX_MESSAGE_PLACEHOLDER => ["Message text...", "Сообщение..."],
        PROMOTION_DIALOG_QUESTION => ["Select a piece to which you want to promote", "Выберите фигуру, в которую хотите превратиться"],
        PROMOTION_DIALOG_TITLE => ["Promotion selection", "Превращение"],
        CHAMELEON_DIALOG_QUESTION => ["Morph into an eaten piece?", "Превратиться в съеденную фигуру?"],
        CHAMELEON_DIALOG_TITLE => ["Chameleon confirmation", "Хамелеон"],
        INCOMING_CHALLENGE_TITLE => ["Incoming challenge", "Входящий вызов"],
        INCOMING_CHALLENGE_TEXT => ["$0 wants to play with you ($1). Accept the challenge?", "$0 хочет с вами сыграть ($1). Принять вызов?"],
        /*
        ACCEPT_CHALLENGE => ["Accept challenge", "Принять вызов"],
        SEND_CHALLENGE_RESULT_SUCCESS => ["Challenge sent to ", "Вызов отправлен игроку "],
        SEND_CHALLENGE_RESULT_DECLINED => [" has declined your challenge", " отклонил(а) ваш вызов"],
        SEND_CHALLENGE_RESULT_SAME => ["You can't challenge yourself", "Вы не можете отправлять вызов самому себе"],
        SEND_CHALLENGE_RESULT_REPEATED => ["You have already sent a challenge to this player", "Вы уже отправили этому игроку вызов"],
        SEND_CHALLENGE_RESULT_OFFLINE => ["Callee is offline", "Вызванный игрок не в сети"],
        SEND_CHALLENGE_RESULT_BUSY => ["Callee is currently playing", "Вызванный игрок в игре"],
        SEND_CHALLENGE_RESULT_DECLINED_TITLE => ["Challenge declined", "Вызов отклонен"],
        SEND_CHALLENGE_RESULT_ERROR_TITLE => ["Challenge error", "Ошибка вызова"],
        SEND_CHALLENGE_RESULT_SUCCESS_TITLE => ["Success", "Успех"],
        */
        SPECTATOR_JOINED_MESSAGE => ["$0 is now spectating", "$0 стал наблюдателем"],
        SPECTATOR_LEFT_MESSAGE => ["$0 left", "$0 вышел"],
        OPENING_STARTING_POSITION => ["Starting position", "Начальная позиция"],
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
        ABORT_CONFIRMATION_MESSAGE => ["Are you sure you want to abort the game?", "Вы уверены, что хотите прервать игру?"],
        ENTER_PROFILE_OWNER => ["Enter the login of a profile owner", "Введите логин игрока, профиль которого вы хотите посетить"],
        /*
        SEND_CHALLENGE_RESULT_NOTFOUND => ["Callee not found", "Вызываемый игрок не найден"],
        ACCEPT_CHALLENGE_RESULT_CANCELLED => ["A challenge has been cancelled", "Оппонент отменил вызов"],
        ACCEPT_CHALLENGE_RESULT_OFFLINE => ["Caller is offline", "Оппонент не в сети"],
        ACCEPT_CHALLENGE_RESULT_BUSY => ["Caller is currently playing", "Оппонент в игре"],
        */

        SESSION_CLOSED_ALERT_TITLE => ["Connection Closed", "Соединение закрыто"],
        SESSION_CLOSED_ALERT_TEXT => ["Connection was closed. Either you logged from another tab, browser or device or you were inactive for too long. Reload the page to reconnect", "Соединение было разорвано. Либо вы подключились из другой вкладки, из другого браузера или с другого устройства, либо же вы были неактивны слишком долго. Перезагрузите страницу для переподключения"],
        RECONNECTION_POP_UP_TEXT => ["Reconnecting...", "Восстанавливаем соединение..."],
        RECONNECTION_POP_UP_TITLE => ["Connection lost", "Потеряно соединение"],
        CONNECTION_LOST_ERROR => ["Connection lost", "Потеряно соединение"],
        CONNECTION_ERROR_DIALOG_TITLE => ["Connection error", "Ошибка подключения"],

        CLIPBOARD_ERROR_ALERT_TITLE => ["Clipboard Error", "Ошибка буфера обмена"],
        CLIPBOARD_ERROR_ALERT_TEXT => ["Failed to copy: $0", "Копирование не удалось: $0"],
        
        CORRESPONDENCE_TIME_CONTROL_NAME => ["Correspondence", "По переписке"],
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