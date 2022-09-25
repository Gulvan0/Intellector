package dict;

import struct.PieceColor;
import struct.Outcome;

class Dictionary 
{
    private static function getTranslations(phrase:Phrase):Array<String>
    {
        switch phrase
        {
            case LANGUAGE_NAME:
                return ["English", "Русский"];
            case ANALYSIS_SET_POSITION_BTN_TOOLTIP:
                return ["Set position", "Задать позицию"];
            case ANALYSIS_SHARE_BTN_TOOLTIP:
                return ["Share", "Поделиться"];
            case ANALYSIS_OVERVIEW_TAB_NAME:
                return ["Overview", "Обзор"];
            case ANALYSIS_BRANCHING_TAB_NAME:
                return ["Branches", "Ветви"];
            case ANALYSIS_OPENINGS_TAB_NAME:
                return ["Openings", "Дебюты"];
            case ANALYSIS_OPENINGS_TEASER_TEXT:
                return ["Coming soon", "Скоро"];
            case ANALYSIS_CLEAR_BTN_TOOLTIP:
                return ["Clear", "Очистить"];
            case ANALYSIS_RESET_BTN_TOOLTIP:
                return ["Reset", "Заново"];
            case ANALYSIS_IMPORT_BTN_TOOLTIP:
                return ["Import from SIP", "Импорт из SIP"];
            case ANALYSIS_FLIP_BOARD_BTN_TOOLTIP:
                return ["Flip board", "Перевернуть доску"];
            case ANALYSIS_TO_STARTPOS_BTN_TOOLTIP:
                return ["To starting position", "К начальной расстановке"];
            case ANALYSIS_WHITE_TO_MOVE_OPTION_TEXT:
                return ["White to Move", "Ход белых"];
            case ANALYSIS_BLACK_TO_MOVE_OPTION_TEXT:
                return ["Black to Move", "Ход черных"];
            case ANALYSIS_APPLY_CHANGES_BTN_TEXT:
                return ["Apply changes", "Применить изменения"];
            case ANALYSIS_DISCARD_CHANGES_BTN_TEXT:
                return ["Discard changes", "Отклонить изменения"];
            case ANALYSIS_INPUT_SIP_PROMPT_TEXT:
                return ["Input SIP", "Введите SIP"];
            case ANALYSIS_INVALID_SIP_WARNING_TITLE:
                return ["Warning: Invalid SIP", "Ошибка: Недопустимый SIP"];
            case ANALYSIS_INVALID_SIP_WARNING_TEXT:
                return ["The specified SIP is invalid", "Введенная вами строка не является допустимым SIP"];
            case ANALYSIS_BRANCHING_HELP_LINK_TEXT:
                return ["Branching Help", "Справка по дереву вариантов"];
            case ANALYSIS_BRANCHING_HELP_DIALOG_TITLE:
                return ["Branching Help", "Справка (дерево вариантов)"];
            case ANALYSIS_BRANCHING_HELP_DIALOG_TEXT:
                return ["<p><u><b>General</b></u></p><br><p><em>Use branching tab to navigate between different variations of the study. You can change the mode in settings.</em></p><br><p><b>LMB (Click):</b> Switch to branch</p><br><p><b>CTRL + LMB (Click):</b> Remove branch</p><br><p><b>Mouse wheel:</b> Scroll vertically</p><br><p><b>SHIFT + Mouse wheel:</b> Scroll horizontally</p><br><p>Alternatively, <b>Click &amp; Hold LMB</b> while moving the mouse to drag</p><br><p><u><b>Tree Mode</b></u></p><br><p><b>CTRL + Mouse wheel:</b> Zoom in / out</p>", ""];
            case SHARE_DIALOG_TITLE:
                return ["Share", "Поделиться"];
            case SHARE_POSITION_TAB_NAME:
                return ["Share Position", "Поделиться позицией"];
            case SHARE_SIP_HEADER:
                return ["SIP", "SIP"];
            case SHARE_IMAGE_HEADER:
                return ["Image", "Картинка"];
            case SHARE_DOWNLOAD_PNG_BTN_TEXT:
                return ["Download PNG", "Скачать PNG"];
            case SHARE_DOWNLOAD_PNG_MARKUP_CHECKBOX_TEXT:
                return ["Add Markup", "Добавить метки"];
            case SHARE_DOWNLOAD_PNG_DIMENSIONS_LABEL_TEXT:
                return ["Dimensions: ", "Размер: "];
            case SHARE_DOWNLOAD_PNG_KEEP_RATIO_CHECKBOX_TEXT:
                return ["Keep Aspect Ratio", "Сохранять пропорции"];
            case SHARE_DOWNLOAD_PNG_BGCOLOR_LABEL_TEXT:
                return ["Background Color: ", "Цвет фона: "];
            case SHARE_DOWNLOAD_PNG_TRANSPARENT_BG_CHECKBOX_TEXT:
                return ["Transparent Background", "Прозрачный фон"];
            case SHARE_GAME_TAB_NAME:
                return ["Share Game", "Поделиться игрой"];
            case SHARE_LINK_HEADER:
                return ["Link", "Ссылка"];
            case SHARE_PIN_HEADER:
                return ["PIN", "PIN"];
            case SHARE_ANIMATED_GIF_HEADER:
                return ["Animated GIF", "Анимированная GIF"];
            case SHARE_DOWNLOAD_GIF_WIDTH_LABEL_TEXT:
                return ["Width: ", "Ширина: "];
            case SHARE_DOWNLOAD_GIF_INTERVAL_LABEL_TEXT:
                return ["Interval (ms): ", "Интервал (мс): "];
            case SHARE_EXPORT_AND_DOWNLOAD_BTN_TEXT:
                return ["Export & Download", "Скачать"];
            case SHARE_EXPORT_TAB_NAME:
                return ["Export", "Экспорт"];
            case SHARE_EXPORT_AS_STUDY_HEADER:
                return ["Export as Study", "Экспорт студии"];
            case SHARE_NAME_PREFIX_LABEL:
                return ["Name: ", "Название: "];
            case SHARE_STUDY_NAME_TEXTFIELD_PLACEHOLDER:
                return ["Enter study name...", "Название студии..."];
            case SHARE_EXPORT_NEW_BTN_TEXT:
                return ["Create New Study", "Создать новую студию"];
            case SHARE_OVERWRITE_BTN_TEXT_TEMPLATE:
                return ["Overwrite $0", "Перезаписать $0"];
            case SHARE_EXPORT_AS_QUESTION_MARKS_TEASER:
                return ["Export as ???", "Экспорт ???"];
            case SHARE_COMING_SOON:
                return ["Coming soon!", "Скоро!"];
            case COPY_BTN_TOOLTIP:
                return ["Copy", "Копировать"];
            case COPY_BTN_SUCCESS_TOOLTIP:
                return ["Copied!", "Скопировано!"];
            case LIVE_SHARE_BTN_TOOLTIP:
                return ["Share", "Поделиться"];
            case OPENJOIN_CHALLENGE_BY_HEADER:
                return ["Challenge by $0", "Вызов $0"];
            case OPENJOIN_COLOR_WHITE_OWNER:
                return ["$0 will play as White", "$0 играет белыми"];
            case OPENJOIN_COLOR_BLACK_OWNER:
                return ["$0 will play as Black", "$0 играет черными"];
            case OPENJOIN_COLOR_RANDOM:
                return ["Random color", "Случайный цвет"];
            case OPENJOIN_RATED:
                return ["Rated", "Рейтинговая"];
            case OPENJOIN_UNRATED:
                return ["Unrated", "Товарищеская"];
            case OPENJOIN_ACCEPT_BTN_TEXT:
                return ["Accept Challenge", "Принять вызов"];
            case OPENJOIN_ESSENTIAL_PARAMS_LABEL_TEXT:
                return ["Features:", "Особенности:"];
            case MENUBAR_PLAY_MENU_TITLE:
                return ["Play", "Играть"];
            case MENUBAR_PLAY_MENU_CREATE_GAME_ITEM:
                return ["Create Game", "Создать игру"];
            case MENUBAR_PLAY_MENU_OPEN_CHALLENGES_ITEM:
                return ["Open Challenges", "Открытые вызовы"];
            case MENUBAR_SPECTATE_MENU_TITLE:
                return ["Spectate", "Смотреть"];
            case MENUBAR_SPECTATE_MENU_CURRENT_GAMES_ITEM:
                return ["Current Games", "Текущие партии"];
            case MENUBAR_SPECTATE_MENU_FOLLOW_PLAYER_ITEM:
                return ["Follow Player", "Наблюдать за игроком"];
            case MENUBAR_LEARN_MENU_TITLE:
                return ["Learn", "Учёба"];
            case MENUBAR_LEARN_MENU_ANALYSIS_BOARD_ITEM:
                return ["Analysis Board", "Доска анализа"];
            case MENUBAR_SOCIAL_MENU_TITLE:
                return ["Social", "Сообщество"];
            case MENUBAR_SOCIAL_MENU_PLAYER_PROFILE_ITEM:
                return ["Player Profile", "Профиль игрока"];
            case MENUBAR_CHALLENGES_HEADER_INCOMING_CHALLENGE:
                return ["Incoming Challenge", "Входящий вызов"];
            case MENUBAR_CHALLENGES_HEADER_OUTGOING_CHALLENGE:
                return ["Outgoing Challenge", "Исходящий вызов"];
            case MENUBAR_CHALLENGES_FROM_LINE_TEXT:
                return ["From: $0", "От: $0"];
            case MENUBAR_CHALLENGES_TO_LINE_TEXT:
                return ["To: $0", "Кому: $0"];
            case MENUBAR_CHALLENGES_ACCEPT_BUTTON_TEXT:
                return ["Accept", "Принять"];
            case MENUBAR_CHALLENGES_DECLINE_BUTTON_TEXT:
                return ["Decline", "Отклонить"];
            case MENUBAR_CHALLENGES_CANCEL_BUTTON_TEXT:
                return ["Cancel challenge", "Отменить вызов"];
            case MENUBAR_ACCOUNT_MENU_LOGIN_ITEM:
                return ["Log In", "Войти"];
            case MENUBAR_ACCOUNT_MENU_MY_PROFILE_ITEM:
                return ["My Profile", "Мой профиль"];
            case MENUBAR_ACCOUNT_MENU_SETTINGS_ITEM:
                return ["Settings", "Настройки"];
            case MENUBAR_ACCOUNT_MENU_LOGOUT_ITEM:
                return ["Log Out", "Выйти"];
            case MENUBAR_ACCOUNT_MENU_GUEST_DISPLAY_NAME:
                return ["Guest", "Гость"];
            case CHANGELOG_DIALOG_TITLE:
                return ["Changelog", "Список изменений"];
            case LOGIN_DIALOG_TITLE:
                return ["Authorization", "Авторизация"];
            case LOGIN_LOG_IN_MODE_TITLE:
                return ["Log In", "Вход"];
            case LOGIN_REGISTER_MODE_TITLE:
                return ["Sign Up", "Регистрация"];
            case LOGIN_LOGIN_FIELD_NAME:
                return ["Login", "Логин"];
            case LOGIN_PASSWORD_FIELD_NAME:
                return ["Password", "Пароль"];
            case LOGIN_REPEAT_PASSWORD_FIELD_NAME:
                return ["Repeat password", "Повторите пароль"];
            case LOGIN_REMEMBER_ME:
                return ["Remember me", "Запомнить"];
            case LOGIN_REMAIN_LOGGED:
                return ["Stay logged in", "Оставаться в сети"];
            case LOGIN_WARNING_MESSAGEBOX_TITLE:
                return ["Authorization failed", "Ошибка авторизации"];
            case LOGIN_INVALID_PASSWORD_WARNING_TEXT:
                return ["Invalid login or password", "Неверный логин или пароль"];
            case LOGIN_PASSWORDS_DO_NOT_MATCH:
                return ["Passwords do not match", "Введенные пароли не совпадают"];
            case LOGIN_ALREADY_REGISTERED_WARNING_TEXT:
                return ["An user with this login already exists", "Пользователь с таким логином уже существует"];
            case LOGIN_LOGIN_NOT_SPECIFIED_WARNING_TEXT:
                return ["Login is not specified!", "Не указан логин!"];
            case LOGIN_PASSWORD_NOT_SPECIFIED_WARNING_TEXT:
                return ["Password is not specified!", "Не указан пароль!"];
            case LOGIN_REPEATED_PASSWORD_NOT_SPECIFIED_WARNING_TEXT:
                return ["\"Repeat Password\" field is empty!", "Поле \"Повторите пароль\" не заполнено!"];
            case LOGIN_BAD_LOGIN_LENGTH_WARNING_TEXT:
                return ["Login must contain between 2 and 16 characters", "Длина логина должна быть в диапазоне 2-16 символов"];
            case LOGIN_BAD_PASSWORD_LENGTH_WARNING_TEXT:
                return ["Password must contain at least 6 characters", "Длина пароля должна составлять не менее 6 символов"];
            case SETTINGS_DIALOG_TITLE:
                return ["Settings", "Настройки"];
            case SETTINGS_GENERAL_TAB_TITLE:
                return ["General", "Основные"];
            case SETTINGS_APPEARANCE_TAB_TITLE:
                return ["Appearance", "Внешний вид"];
            case SETTINGS_CONTROLS_TAB_TITLE:
                return ["Controls", "Управление"];
            case SETTINGS_INTEGRATIONS_TAB_TITLE:
                return ["Integrations", "Интеграции"];
            case SETTINGS_LANGUAGE_OPTION_NAME:
                return ["Language", "Язык"];
            case SETTINGS_MARKUP_OPTION_NAME:
                return ["Coordinates", "Координаты"];
            case SETTINGS_PREMOVES_OPTION_NAME:
                return ["Premoves", "Предходы"];
            case SETTINGS_BRANCHING_TYPE_OPTION_NAME:
                return ["Branching mode", "Вид ветвей"];
            case SETTINGS_BRANCHING_SHOW_TURN_COLOR_OPTION_NAME:
                return ["Display turn color in Tree mode", "Отображать цвет хода в режиме Дерева"];
            case SETTINGS_SILENT_CHALLENGES_OPTION_NAME:
                return ["Ignore incoming challenges", "Не уведомлять о входящих вызовах"];
            case SETTINGS_MARKUP_ALL_OPTION_VALUE:
                return ["All", "Все"];
            case SETTINGS_MARKUP_LETTERS_OPTION_VALUE:
                return ["Files only", "Только вертикали"];
            case SETTINGS_MARKUP_NONE_OPTION_VALUE:
                return ["None", "Нет"];
            case SETTINGS_BRANCHING_TYPE_TREE_OPTION_VALUE:
                return ["Tree", "Дерево"];
            case SETTINGS_BRANCHING_TYPE_OUTLINE_OPTION_VALUE:
                return ["Outline", "Список"];
            case SETTINGS_BRANCHING_TYPE_PLAIN_OPTION_VALUE:
                return ["Plain text", "Текст"];
            case SETTINGS_DISABLED_OPTION_VALUE:
                return ["Disabled", "Нет"];
            case SETTINGS_ENABLED_OPTION_VALUE:
                return ["Enabled", "Да"];
            case PROFILE_ROLE_TEXT(Admin):
                return ["Main Developer", "Главный разработчик"];
            case PROFILE_ROLE_TEXT(AnacondaDeveloper):
                return ["Anaconda Developer", "Создатель Анаконды"];
            case PROFILE_STATUS_TEXT(Offline(_)):
                return ["Last seen: $0", "Был в сети: $0"];
            case PROFILE_STATUS_TEXT(Online):
                return ["Online now", "В сети"];
            case PROFILE_STATUS_TEXT(InGame):
                return ["Playing now", "Играет партию"];
            case PROFILE_QUICK_ACTION_SEND_CHALLENGE_TOOLTIP:
                return ["Send Challenge", "Отправить вызов"];
            case PROFILE_QUICK_ACTION_FOLLOW_TOOLTIP:
                return ["Follow", "Следить за игрой"];
            case PROFILE_ACTION_ADD_FRIEND_TOOLTIP:
                return ["Add friend", "Добавить в друзья"];
            case PROFILE_ACTION_REMOVE_FRIEND_TOOLTIP:
                return ["Remove friend", "Удалить из друзей"];
            case PROFILE_FRIENDS_PREPENDER:
                return ["Friends: ", "Друзья: "];
            case PROFILE_STUDY_TAGS_PREPENDER:
                return ["Tags: ", "Теги: "];
            case PROFILE_STUDY_EDIT_BTN_TOOLTIP:
                return ["Edit study", "Редактировать студию"];
            case PROFILE_STUDY_REMOVE_BTN_TOOLTIP:
                return ["Remove study", "Удалить студию"];
            case PROFILE_GAMES_TAB_TITLE:
                return ["Games", "Игры"];
            case PROFILE_STUDIES_TAB_TITLE:
                return ["Studies", "Студии"];
            case PROFILE_ONGOING_MATCHES_TAB_TITLE:
                return ["Ongoing", "Текущие партии"];
            case PROFILE_LOAD_MORE_BTN_TEXT:
                return ["Load more", "Загрузить больше"];
            case PROFILE_RELOAD_BTN_TEXT:
                return ["Reload", "Обновить"];
            case PROFILE_REMOVE_TAG_FILTER_BTN_TOOLTIP:
                return ["Remove tag from filters", "Убрать тег из фильтров"];
            case PROFILE_ADD_TAG_FILTER_BTN_TOOLTIP:
                return ["Add filter by tag", "Добавить фильтр по тегу"];
            case PROFILE_CLEAR_TAG_FILTERS_BTN_TOOLTIP:
                return ["Clear filters", "Очистить фильтры"];
            case PROFILE_TAG_FILTER_PROMPT_QUESTION_TEXT:
                return ["Input tag:", "Введите тег:"];
            
            case MINIPROFILE_DIALOG_TITLE(ownerLogin):
                return ['Player info: $ownerLogin', 'Данные игрока: $ownerLogin'];
            case MINIPROFILE_FOLLOW_BTN_TOOLTIP:
                return ["Follow", "Отслеживать"];
            case MINIPROFILE_UNFOLLOW_BTN_TOOLTIP:
                return ["Stop following", "Перестать отслеживать"];
            case MINIPROFILE_FRIEND_BTN_TOOLTIP:
                return ["Add friend", "Добавить в друзья"];
            case MINIPROFILE_UNFRIEND_BTN_TOOLTIP:
                return ["Remove friend", "Удалить из друзей"];
            case MINIPROFILE_CHALLENGE_BTN_TOOLTIP:
                return ["Send challenge", "Вызвать на игру"];
            case MINIPROFILE_TO_PROFILE_BTN_TOOLTIP:
                return ["To profile", "Открыть профиль"];

            case MAIN_MENU_CREATE_GAME_BTN_TEXT:
                return ["Create Game", "Создать игру"];
            case READ_FULL_CHANGELOG_TOOLTIP:
                return ["Read full changelog", "Полный список изменений"];
            case TABLEVIEW_RELOAD_BTN_TEXT:
                return ["Reload", "Обновить"];
            case TABLEVIEW_MODE_COLUMN_NAME:
                return ["Mode", "Режим"];
            case TABLEVIEW_TIME_COLUMN_NAME:
                return ["Time", "Контроль"];
            case TABLEVIEW_PLAYER_COLUMN_NAME:
                return ["Player", "Игрок"];
            case TABLEVIEW_PLAYERS_COLUMN_NAME:
                return ["Players", "Игроки"];
            case TABLEVIEW_BRACKET_COLUMN_NAME:
                return ["Bracket", "Тип"];
            case TABLEVIEW_BRACKET_RANKED(false):
                return ["Rated", "На рейтинг"];
            case TABLEVIEW_BRACKET_RANKED(true):
                return ["Unrated", "Товарищеская"];
            case CURRENT_GAMES_TABLE_HEADER:
                return ["Now Playing", "Текущие игры"];
            case PAST_GAMES_TABLE_HEADER:
                return ["Recent Games", "Недавние партии"];
            case OPEN_CHALLENGES_TABLE_HEADER:
                return ["Open Challenges", "Открытые вызовы"];
            case CHALLENGE_COLOR_ICON_TOOLTIP(null):
                return ["Your color will be selected randomly", "Цвет будет выбран случайным образом"];
            case CHALLENGE_COLOR_ICON_TOOLTIP(White):
                return ["You will play as White", "Вы будете играть за белых"];
            case CHALLENGE_COLOR_ICON_TOOLTIP(Black):
                return ["You will play as Black", "Вы будете играть за черных"];

            case GAME_ENDED_DIALOG_TITLE:
                return ["Game over", "Игра окончена"];
            case GAME_ENDED_PLAYER_DIALOG_MESSAGE(Mate(winnerColor), playerColor) if (playerColor == winnerColor):
                return ["Your opponent's Intellector has been captured. You won!", "Интеллектор противника пал. Вы победили!"];
            case GAME_ENDED_PLAYER_DIALOG_MESSAGE(Mate(winnerColor), playerColor):
                return ["Your Intellector has been captured. You lost.", "Ваш Интеллектор пал. Вы проиграли."];
            case GAME_ENDED_PLAYER_DIALOG_MESSAGE(Breakthrough(winnerColor), playerColor) if (playerColor == winnerColor):
                return ["Your Intellector has reached the last rank. You won!", "Ваш Интеллектор достиг последней горизонтали. Вы победили!"];
            case GAME_ENDED_PLAYER_DIALOG_MESSAGE(Breakthrough(winnerColor), playerColor):
                return ["Your opponent's Intellector has reached the last rank. You lost.", "Вражеский Интеллектор достиг последней горизонтали. Вы проиграли."];
            case GAME_ENDED_PLAYER_DIALOG_MESSAGE(Timeout(winnerColor), playerColor) if (playerColor == winnerColor):
                return ["Your opponent has run out of time. You won!", "У вашего противника закончилось время. Вы победили!"];
            case GAME_ENDED_PLAYER_DIALOG_MESSAGE(Timeout(winnerColor), playerColor):
                return ["You lost on time.", "У вас закончилось время. Вы проиграли."];
            case GAME_ENDED_PLAYER_DIALOG_MESSAGE(Resign(winnerColor), playerColor) if (playerColor == winnerColor):
                return ["Your opponent has resigned. You won!", "Ваш противник сдался. Вы победили!"];
            case GAME_ENDED_PLAYER_DIALOG_MESSAGE(Resign(winnerColor), playerColor):
                return ["You lost by resignation.", "Вы сдались; в игре засчитано поражение"];
            case GAME_ENDED_PLAYER_DIALOG_MESSAGE(Abandon(winnerColor), playerColor) if (playerColor == winnerColor):
                return ["Your opponent has abandoned the game. You won!", "Ваш противник покинул партию. Вы победили!"];
            case GAME_ENDED_PLAYER_DIALOG_MESSAGE(Abandon(winnerColor), playerColor):
                return ["You lost (game abandoned).", "Игра покинута. Вы проиграли."];
            case GAME_ENDED_SPECTATOR_DIALOG_MESSAGE(Mate(_), winnerLogin, loserLogin):
                return ['$loserLogin\'s Intellector has been captured. $winnerLogin won.', 'Интеллектор игрока $loserLogin повержен. Победитель: $winnerLogin.'];
            case GAME_ENDED_SPECTATOR_DIALOG_MESSAGE(Breakthrough(_), winnerLogin, loserLogin):
                return ['$winnerLogin\'s Intellector has reached the last rank. $winnerLogin won.', 'Интеллектор игрока $winnerLogin достиг последней горизонтали. Победитель: $winnerLogin.'];
            case GAME_ENDED_SPECTATOR_DIALOG_MESSAGE(Timeout(_), winnerLogin, loserLogin):
                return ['$loserLogin has lost on time. $winnerLogin won.', 'Игрок $loserLogin просрочил время. Победитель: $winnerLogin.'];
            case GAME_ENDED_SPECTATOR_DIALOG_MESSAGE(Resign(_), winnerLogin, loserLogin):
                return ['$loserLogin has resigned. $winnerLogin won.', 'Игрок $loserLogin сдался. Победитель: $winnerLogin.'];
            case GAME_ENDED_SPECTATOR_DIALOG_MESSAGE(Abandon(_), winnerLogin, loserLogin):
                return ['$loserLogin has left the game. $winnerLogin won.', 'Игрок $loserLogin покинул партию. Победитель: $winnerLogin.'];
            case GAME_ENDED_PLAYER_DIALOG_MESSAGE(DrawAgreement, _), GAME_ENDED_SPECTATOR_DIALOG_MESSAGE(DrawAgreement, _, _):
                return ["Game has ended up in a draw. Reason: mutual agreement.", "Игра завершена вничью. Причина: взаимное согласие"];
            case GAME_ENDED_PLAYER_DIALOG_MESSAGE(Repetition, _), GAME_ENDED_SPECTATOR_DIALOG_MESSAGE(Repetition, _, _):
                return ["Game has ended up in a draw. Reason: threefold repetition.", "Игра завершена вничью. Причина: троекратное повторение"];
            case GAME_ENDED_PLAYER_DIALOG_MESSAGE(NoProgress, _), GAME_ENDED_SPECTATOR_DIALOG_MESSAGE(NoProgress, _, _):
                return ["Game has ended up in a draw. Reason: sixty-move rule.", "Игра завершена вничью. Причина: правило 60 ходов"];
            case GAME_ENDED_PLAYER_DIALOG_MESSAGE(Abort, _), GAME_ENDED_SPECTATOR_DIALOG_MESSAGE(Abort, _, _):
                return ["Game aborted.", "Игра прервана."];

            case LIVE_WATCHING_LABEL_TEXT(watchedPlayerLogin):
                return ['Watching $watchedPlayerLogin', 'Наблюдение за $watchedPlayerLogin'];
            case LIVE_WATCHING_LABEL_TOOLTIP:
                return ["You follow this player. Each time he/she starts a new game, you'll be automatically redirected to watch it. To unfollow, simply leave this screen.", "Вы наблюдаете за этим игроком. Если игрок начнет новую игру, вы автоматически последуете за ним. Чтобы прекратить наблюдение, просто покиньте этот экран"];
                

            case INPUT_PLAYER_LOGIN:
                return ["Input player's username", "Введите ник игрока"];
            case INCOMING_CHALLENGE_DIALOG_TITLE:
                return ["Incoming Challenge", "Входящий вызов"];
            case INCOMING_CHALLENGE_CHALLENGE_BY_LABEL_TEXT:
                return ["$0 challenges you to play a game!", "$0 вызывает вас на игру!"];
            case INCOMING_CHALLENGE_ACCEPT_BTN_TEXT:
                return ["Accept", "Принять"];
            case INCOMING_CHALLENGE_DECLINE_BTN_TEXT:
                return ["Decline", "Отклонить"];
            case INCOMING_CHALLENGE_ACCEPT_ERROR_DIALOG_TITLE:
                return ["Challenge Acceptance Error", "Ошибка принятия вызова"];
            case INCOMING_CHALLENGE_ACCEPT_ERROR_CALLER_OFFLINE:
                return ["Failed to accept challenge: $0 is offline", "Не удалось принять вызов: $0 не в сети"];
            case INCOMING_CHALLENGE_ACCEPT_ERROR_CALLER_INGAME:
                return ["Failed to accept challenge: $0 has already started another game", "Не удалось принять вызов: $0 уже участвует в другой партии"];
            case INCOMING_CHALLENGE_ACCEPT_ERROR_CHALLENGE_CANCELLED:
                return ["Failed to accept challenge: $0 cancelled the challenge", "Не удалось принять вызов: $0 отменил вызов"];
            case SEND_CHALLENGE_ERROR_DIALOG_TITLE:
                return ["Challenge Creation Error", "Ошибка создания вызова"];
            case SEND_CHALLENGE_ERROR_TO_ONESELF:
                return ["Failed to create challenge: cannot send challenge to oneself", "Не удалось создать вызов: вызов не может быть адресован самому себе"];
            case SEND_CHALLENGE_ERROR_NOT_FOUND:
                return ["Failed to create challenge: player not found", "Не удалось создать вызов: игрок не найден"];
            case SEND_CHALLENGE_ERROR_ALREADY_EXISTS:
                return ["Failed to create challenge: you have already sent another challenge to this player. To create a new challenge, you should cancel the previous one first.", "Не удалось создать вызов: вызов, адресованный данному игроку уже существует. Для создания нового вызова, сперва отмените предыдущий."];
            case CHALLENGE_PARAMS_DIALOG_TITLE:
                return ["Challenge Parameters", "Параметры Вызова"];
            case CHALLENGE_PARAMS_TYPE_OPTION_NAME:
                return ["Type", "Тип"];
            case CHALLENGE_PARAMS_TYPE_DIRECT:
                return ["Direct", "Прямой"];
            case CHALLENGE_PARAMS_TYPE_OPEN:
                return ["Open", "Открытый"];
            case CHALLENGE_PARAMS_DIRECT_USERNAME_OPTION_NAME:
                return ["Username", "Ник"];
            case CHALLENGE_PARAMS_OPEN_VISIBILITY:
                return ["Visibility", "Видимость"];
            case CHALLENGE_PARAMS_OPEN_VISIBILITY_ALL:
                return ["Public", "Публичный"];
            case CHALLENGE_PARAMS_OPEN_VISIBILITY_BY_LINK:
                return ["Link only", "Только по ссылке"];
            case CHALLENGE_PARAMS_OPEN_LINK_HEADER:
                return ["Link", "Ссылка"];
            case CHALLENGE_PARAMS_TIME_CONTROL_OPTION_NAME:
                return ["Time Control", "Контроль времени"];
            case CHALLENGE_PARAMS_TIME_CONTROL_START_OPTION_NAME:
                return ["Initial Time", "На партию"];
            case CHALLENGE_PARAMS_TIME_CONTROL_INCREMENT_OPTION_NAME:
                return ["Bonus per Turn", "Бонус за ход"];
            case CHALLENGE_PARAMS_TIME_CONTROL_MINS_APPENDIX:
                return ["m", "м"];
            case CHALLENGE_PARAMS_TIME_CONTROL_SECS_APPENDIX:
                return ["s", "с"];
            case CHALLENGE_PARAMS_TIME_CONTROL_CORRESPONDENCE_CHECK_NAME:
                return ["No control", "Без контроля"];
            case CHALLENGE_PARAMS_RANKED_CHECK_NAME:
                return ["Rated", "На рейтинг"];
            case CHALLENGE_PARAMS_RATED_ANY_ELO_CHECK_NAME:
                return ["Any opponent", "Любой противник"];
            case CHALLENGE_PARAMS_RATED_MAXDIFF_OPTION_NAME:
                return ["Max ELO difference", "Макс. разница ELO"];
            case CHALLENGE_PARAMS_COLOR_OPTION_NAME:
                return ["I Play", "Я играю"];
            case CHALLENGE_PARAMS_COLOR_RANDOM:
                return ["Random color", "Случайным цветом"];
            case CHALLENGE_PARAMS_COLOR_WHITE:
                return ["White", "Белыми"];
            case CHALLENGE_PARAMS_COLOR_BLACK:
                return ["Black", "Черными"];
            case CHALLENGE_PARAMS_STARTPOS_OPTION_NAME:
                return ["Starting Position", "Начальная позиция"];
            case CHALLENGE_PARAMS_STARTPOS_DEFAULT:
                return ["Default", "Стандартная"];
            case CHALLENGE_PARAMS_STARTPOS_CUSTOM:
                return ["Custom", "Особая"];
            case CHALLENGE_PARAMS_STARTPOS_SIP_OPTION_NAME:
                return ["SIP", "SIP"];
            case CHALLENGE_PARAMS_CONFIRM_BTN_TEXT:
                return ["Create Challenge", "Создать вызов"];
            case CHALLENGE_PARAMS_INVALID_SIP_WARNING_TITLE:
                return ["Warning: Invalid SIP", "Ошибка: Недопустимый SIP"];
            case CHALLENGE_PARAMS_INVALID_SIP_WARNING_TEXT:
                return ["The specified SIP is invalid", "Введенная вами строка не является допустимым SIP"];
            case CHALLENGE_PARAMS_INVALID_STARTPOS_WARNING_TITLE:
                return ["Warning: Invalid position", "Ошибка: Недопустимая позиция"];
            case CHALLENGE_PARAMS_INVALID_STARTPOS_WARNING_TEXT:
                return ["Custom starting position should contain one Intellector of each color. Additionally, none of them may be placed on the final rank", "Стартовая позиция должна содержать по одному Интеллектору каждого цвета, при этом ни один из Интов не может находиться на последней горизонтали"];
            case REQUESTS_ERROR_DIALOG_TITLE:
                return ["Error", "Ошибка"];
            case REQUESTS_ERROR_CHALLENGE_NOT_FOUND:
                return ["Challenge not found", "Вызов не найден"];
            case REQUESTS_ERROR_PLAYER_NOT_FOUND:
                return ["Player not found", "Игрок не найден"];
            case REQUESTS_ERROR_STUDY_NOT_FOUND:
                return ["Study not found", "Студия не найдена"];
            case REQUESTS_ERROR_PLAYER_OFFLINE:
                return ["This player is offline", "Игрок не в сети"];
            case REQUESTS_ERROR_PLAYER_NOT_IN_GAME:
                return ["This player is not in the game", "В настоящий момент игрок не участвует в партии"];
            case TURN_COLOR(White):
                return ["White to move", "Ход белых"];
            case TURN_COLOR(Black):
                return ["Black to move", "Ход черных"];
            case CUSTOM_STARTING_POSITION:
                return ["Custom starting position", "Нестандартная начальная расстановка"];
            case CHATBOX_MESSAGE_PLACEHOLDER:
                return ["Message text...", "Сообщение..."];
            case PROMOTION_DIALOG_QUESTION:
                return ["Select a piece to which you want to promote", "Выберите фигуру, в которую хотите превратиться"];
            case PROMOTION_DIALOG_TITLE:
                return ["Promotion selection", "Превращение"];
            case CHAMELEON_DIALOG_QUESTION:
                return ["Morph into an eaten piece?", "Превратиться в съеденную фигуру?"];
            case CHAMELEON_DIALOG_TITLE:
                return ["Chameleon confirmation", "Хамелеон"];
            case SPECTATOR_JOINED_MESSAGE:
                return ["$0 is now spectating", "$0 стал наблюдателем"];
            case SPECTATOR_LEFT_MESSAGE:
                return ["$0 left", "$0 вышел"];
            case OPENING_STARTING_POSITION:
                return ["Starting position", "Начальная позиция"];
            case RESIGN_BTN_ABORT_TOOLTIP:
                return ["Abort", "Прервать"];
            case REMATCH_BTN_TOOLTIP:
                return ["Rematch", "Реванш"];
            case EXPLORE_IN_ANALYSIS_BTN_TOOLTIP:
                return ["Explore on analysis board", "На доску анализа"];
            case ADD_TIME_BTN_TOOLTIP:
                return ["Add time", "Добавить время"];
            case PLAY_FROM_POS_BTN_TOOLTIP:
                return ["Play from here", "Доиграть отсюда"];
            case OFFER_DRAW_BTN_TOOLTIP:
                return ["Offer draw", "Ничья"];
            case TAKEBACK_BTN_TOOLTIP:
                return ["Takeback", "Запросить возврат хода"];
            case CANCEL_DRAW_BTN_TOOLTIP:
                return ["Cancel draw", "Отменить ничью"];
            case CANCEL_TAKEBACK_BTN_TOOLTIP:
                return ["Cancel takeback", "Отменить возврат хода"];
            case RESIGN_BTN_TOOLTIP:
                return ["Resign", "Сдаться"];
            case CHANGE_ORIENTATION_BTN_TOOLTIP:
                return ["Flip board", "Перевернуть доску"];
            case RESIGN_CONFIRMATION_MESSAGE:
                return ["Are you sure you want to resign?", "Вы уверены, что хотите сдаться?"];
            case DRAW_QUESTION_TEXT:
                return ["Accept draw?", "Принять ничью?"];
            case TAKEBACK_QUESTION_TEXT:
                return ["Accept takeback?", "Дать переходить?"];
            case DRAW_OFFERED_MESSAGE:
                return ["Draw offered", "Ничья предложена"];
            case DRAW_CANCELLED_MESSAGE:
                return ["Draw cancelled", "Предложение ничьи отменено"];
            case DRAW_ACCEPTED_MESSAGE:
                return ["Draw accepted", "Ничья принята"];
            case DRAW_DECLINED_MESSAGE:
                return ["Draw declined", "Ничья отклонена"];
            case TAKEBACK_OFFERED_MESSAGE:
                return ["Takeback offered", "Тейкбек предложен"];
            case TAKEBACK_CANCELLED_MESSAGE:
                return ["Takeback cancelled", "Запрос тейкбека отменен"];
            case TAKEBACK_ACCEPTED_MESSAGE:
                return ["Takeback accepted", "Тейкбек принят"];
            case TAKEBACK_DECLINED_MESSAGE:
                return ["Takeback declined", "Тейкбек отклонен"];
            case OPPONENT_DISCONNECTED_MESSAGE:
                return ["$0 disconnected", "$0 отключились"];
            case OPPONENT_RECONNECTED_MESSAGE:
                return ["$0 reconnected", "$0 переподключились"];
            case ABORT_CONFIRMATION_MESSAGE:
                return ["Are you sure you want to abort the game?", "Вы уверены, что хотите прервать игру?"];
            case SESSION_CLOSED_ALERT_TITLE:
                return ["Connection Closed", "Соединение закрыто"];
            case SESSION_CLOSED_ALERT_TEXT:
                return ["Connection was closed. Either you logged from another tab, browser or device or you were inactive for too long. Reload the page to reconnect", "Соединение было разорвано. Либо вы подключились из другой вкладки, из другого браузера или с другого устройства, либо же вы были неактивны слишком долго. Перезагрузите страницу для переподключения"];
            case RECONNECTION_POP_UP_TEXT:
                return ["Reconnecting...", "Восстанавливаем соединение..."];
            case RECONNECTION_POP_UP_TITLE:
                return ["Connection lost", "Потеряно соединение"];
            case CONNECTION_LOST_ERROR:
                return ["Connection lost", "Потеряно соединение"];
            case CONNECTION_ERROR_DIALOG_TITLE:
                return ["Connection error", "Ошибка подключения"];
            case CLIPBOARD_ERROR_ALERT_TITLE:
                return ["Clipboard Error", "Ошибка буфера обмена"];
            case CLIPBOARD_ERROR_ALERT_TEXT:
                return ["Failed to copy: $0", "Копирование не удалось: $0"];
            case CORRESPONDENCE_TIME_CONTROL_NAME:
                return ["Correspondence", "По переписке"];
        }
    }

    public static function getPhrase(phrase:Phrase, ?substitutions:Array<String>):String
    {
        var translations = getTranslations(phrase);
        var translation = chooseTranslation(translations);
        if (substitutions != null)
            for (i in 0...substitutions.length)
                translation = StringTools.replace(translation, '$' + i, substitutions[i]);
        return translation;
    }

    public static function chooseTranslation(translations:Array<String>):String
    {
        return translations[Preferences.language.get().getIndex()];
    }

    public static function getLanguageName(lang:Language)
    {
        return getTranslations(LANGUAGE_NAME)[lang.getIndex()];
    }
}