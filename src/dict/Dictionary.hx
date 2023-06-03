package dict;

import net.shared.Constants;
import utils.StringUtils.eloToStr;
import net.shared.PieceColor;
import net.shared.Outcome;

using utils.StringUtils;

class Dictionary 
{
    private static function getTranslations(phrase:Phrase):Array<String>
    {
        switch phrase
        {
            case LANGUAGE_NAME:
                return ["English", "Русский"];

            case MAIN_MENU_SCREEN_TITLE:
                return ["Home", "Главная"];
            case ANALYSIS_BOARD_NO_STUDY_SCREEN_TITLE:
                return ["Analysis Board", "Доска анализа"];
            case STUDY_SCREEN_TITLE(studyID, studyName):
                var shortenedName:String = studyName.shorten();
                return ['Study $shortenedName ($studyID) | Analysis Board', 'Студия $shortenedName ($studyID) | Доска анализа'];
            case PLAYER_PROFILE_SCREEN_TITLE(ownerLogin):
                return ['$ownerLogin\'s profile', 'Профиль $ownerLogin'];
            case CHALLENGE_JOINING_SCREEN_TITLE(ownerLogin):
                return ['Challenge by $ownerLogin', 'Вызов $ownerLogin'];
            case OWN_MATCH_SCREEN_TITLE(opponentRef):
                var opponentStr:String = Utils.playerRef(opponentRef);
                return ['Playing vs $opponentStr', 'Игра против $opponentStr'];
            case SPECTATING_SCREEN_TITLE(whiteRef, blackRef):
                var whiteStr:String = Utils.playerRef(whiteRef);
                var blackStr:String = Utils.playerRef(blackRef);
                return ['Spectating: $whiteStr vs $blackStr', 'Наблюдение: $whiteStr против $blackStr'];
            case PAST_GAME_SCREEN_TITLE(id, whiteRef, blackRef):
                var whiteStr:String = Utils.playerRef(whiteRef);
                var blackStr:String = Utils.playerRef(blackRef);
                return ['Game $id: $whiteStr vs $blackStr', 'Игра $id: $whiteStr против $blackStr'];
                
            case GAME_COMPONENT_PAGE_TITLE(LargeLeftPanelMain):
                return ["", ""];
            case GAME_COMPONENT_PAGE_TITLE(UCMA):
                return ["", ""];
            case GAME_COMPONENT_PAGE_TITLE(AnalysisOverview):
                return ["Overview", "Обзор"];
            case GAME_COMPONENT_PAGE_TITLE(Branching):
                return ["Branches", "Ветви"];
            case GAME_COMPONENT_PAGE_TITLE(PositionEditor):
                return ["Position Editor", "Редактор позиций"];
            case GAME_COMPONENT_PAGE_TITLE(Board):
                return ["", ""];
            case GAME_COMPONENT_PAGE_TITLE(CreepingLine):
                return ["", ""];
            case GAME_COMPONENT_PAGE_TITLE(CompactLiveActionBar):
                return ["", ""];
            case GAME_COMPONENT_PAGE_TITLE(CompactAnalysisActionBar):
                return ["", ""];
            case GAME_COMPONENT_PAGE_TITLE(Chat):
                return ["Chat", "Чат"];
            case GAME_COMPONENT_PAGE_TITLE(GameInfoSubscreen):
                return ["Game Info", "Об игре"];
            case GAME_COMPONENT_PAGE_TITLE(BoardAndClocks):
                return ["", ""];
            case GAME_COMPONENT_PAGE_TITLE(SpecialControlSettings):
                return ["Controls", "Управление"];

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
                return ["<p><u><b>General</b></u></p><p><em>Use branching tab to navigate between different variations of the study. You can change the mode in settings.</em></p><p><b>LMB (Click):</b> Switch to branch</p><p><b>CTRL + LMB (Click):</b> Remove branch</p><p><b>Mouse wheel:</b> Scroll vertically</p><p><b>SHIFT + Mouse wheel:</b> Scroll horizontally</p><p>Alternatively, <b>Click &amp; Hold LMB</b> while moving the mouse to drag</p><p><u><b>Tree Mode</b></u></p><p><b>CTRL + Mouse wheel:</b> Zoom in / out</p>", "<p><u><b>Общее</b></u></p><p><em>Вкладка \"Ветви\" используется для перемещения между различными линиями студии. Вид ветвей можно изменить в настройках.</em></p><p><b>ЛКМ:</b> Переключиться на ветвь</p><p><b>CTRL + ЛКМ:</b> Удалить ветвь</p><p><b>Колесо мыши:</b> Вертикальная прокрутка</p><p><b>SHIFT + Колесо мыши:</b> Горизонтальная прокрутка</p><p>Для перетаскивания <b>Нажмите и удерживайте ЛКМ</b>, передвигая мышь</p><p><u><b>Вид дерева</b></u></p><p><b>CTRL + Колесо мыши:</b> Приблизить / отдалить</p>"];
            
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
                return ["Add Marking", "Добавить разметку"];
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
            case SHARE_EXPORT_AS_STUDY_BTN_TEXT:
                return ["Export Study", "Экспортировать студию"];
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

            case BOT_ANACONDA_THINKING:
                return ["Calculating my next move...", "Думаю над следующим ходом..."];
            case BOT_ANACONDA_PARTIAL_RESULT_ACHIEVED(depth):
                return ['Partial result for depth $depth achieved', 'Расчеты на глубине $depth завершены'];

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

            case MENU_SECTION_TITLE(Play):
                return ["Play", "Играть"];
            case MENU_SECTION_TITLE(Watch):
                return ["Watch", "Смотреть"];
            case MENU_SECTION_TITLE(Learn):
                return ["Learn", "Учёба"];
            case MENU_SECTION_TITLE(Social):
                return ["Social", "Сообщество"];
                
            case MENU_ITEM_NAME(CreateChallenge):
                return ["Create Game", "Создать игру"];
            case MENU_ITEM_NAME(OpenChallenges):
                return ["Open Challenges", "Открытые вызовы"];
            case MENU_ITEM_NAME(PlayVersusBot):
                return ["Versus Bot", "Против компьютера"];
            case MENU_ITEM_NAME(CurrentGames):
                return ["Current Games", "Текущие партии"];
            case MENU_ITEM_NAME(FollowPlayer):
                return ["Follow Player", "Наблюдать за игроком"];
            case MENU_ITEM_NAME(AnalysisBoard):
                return ["Analysis Board", "Доска анализа"];
            case MENU_ITEM_NAME(PlayerProfile):
                return ["Player Profile", "Профиль игрока"];
            case MENU_ITEM_NAME(DiscordServer):
                return ["Discord Server", "Сервер Discord"];
            case MENU_ITEM_NAME(VKGroup):
                return ["VK Group", "Группа VK"];
            case MENU_ITEM_NAME(VKChat):
                return ["VK Chat", "Чат VK"];

            case MENUBAR_CHALLENGES_NO_CHALLENGES_PLACEHOLDER:
                return ["No challenges", "Нет вызовов"];
            case MENUBAR_CHALLENGES_HEADER_INCOMING_CHALLENGE:
                return ["Incoming Challenge", "Входящий вызов"];
            case MENUBAR_CHALLENGES_HEADER_OUTGOING_CHALLENGE:
                return ["Outgoing Challenge", "Исходящий вызов"];
            case MENUBAR_CHALLENGES_FROM_LINE_TEXT:
                return ["From: $0", "От: $0"];
            case MENUBAR_CHALLENGES_TO_LINE_TEXT:
                return ["To: $0", "Кому: $0"];
            case MENUBAR_CHALLENGES_COPY_LINK_TEXT:
                return ["Copy Link", "Копировать ссылку"];
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
            case SETTINGS_AUTOSCROLL_OPTION_NAME:
                return ["Return to the updated current position", "Возвращаться к обновленной текущей позиции"];
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
            case SETTINGS_AUTOSCROLL_ALWAYS_OPTION_VALUE:
                return ["Always", "Всегда"];
            case SETTINGS_AUTOSCROLL_OWN_OPTION_VALUE:
                return ["Own games only", "Только в своих партиях"];
            case SETTINGS_AUTOSCROLL_NEVER_OPTION_VALUE:
                return ["Never", "Никогда"];
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
            case PROFILE_NO_FRIENDS_PLACEHOLDER:
                return ["no friends", "друзей нет"];

            case PROFILE_GAMES_TAB_TITLE:
                return ["Games", "Игры"];
            case PROFILE_STUDIES_TAB_TITLE:
                return ["Studies", "Студии"];
            case PROFILE_ONGOING_MATCHES_TAB_TITLE:
                return ["Ongoing", "Текущие партии"];
                
            case PROFILE_GAMES_TCFILTER_ALL_GAMES_OPTION_NAME:
                return ["All Games", "Все игры"];
            case PROFILE_GAMES_TCFILTER_GAMECNT_LABEL_TEXT(cnt):
                return ['Games: $cnt', 'Игр: $cnt'];
            case PROFILE_GAMES_TCFILTER_ELO_LABEL_TEXT(elo):
                return ['ELO: ${eloToStr(elo)}', 'ELO: ${eloToStr(elo)}'];

            case PROFILE_STUDY_TAG_LABELS_PREPENDER:
                return ["Tags: ", "Теги: "];
            case PROFILE_STUDY_NO_TAGS_PLACEHOLDER:
                return ["<none>", "<нет>"];
            case PROFILE_STUDY_EDIT_BTN_TOOLTIP:
                return ["Edit study", "Редактировать студию"];
            case PROFILE_STUDY_REMOVE_BTN_TOOLTIP:
                return ["Remove study", "Удалить студию"];
            case PROFILE_LOAD_MORE_BTN_TEXT:
                return ["Load more", "Загрузить больше"];
                
            case PROFILE_ONGOING_RELOAD_BTN_TEXT:
                return ["Reload", "Обновить"];

            case PROFILE_TAG_FILTERS_PREPENDER:
                return ["Filter by tags:", "Фильтровать по тегам:"];
            case PROFILE_TAG_NO_FILTERS_PLACEHOLDER_TEXT:
                return ["<none selected>", "<не выбраны>"];
            case PROFILE_REMOVE_TAG_FILTER_BTN_TOOLTIP:
                return ["Remove tag from filters", "Убрать тег из фильтров"];
            case PROFILE_ADD_TAG_FILTER_BTN_TEXT:
                return ["Add filter", "Добавить фильтр"];
            case PROFILE_CLEAR_TAG_FILTERS_BTN_TEXT:
                return ["Clear", "Очистить"];
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
            case TABLEVIEW_BRACKET_RANKED(true):
                return ["Rated", "На рейтинг"];
            case TABLEVIEW_BRACKET_RANKED(false):
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

            case CHATBOX_GAME_OVER_MESSAGE(outcome):
                return Utils.chatboxGameOverMessage(outcome);

            case INVALID_MOVE_DIALOG_TITLE:
                return ["Invalid move", "Недопустимый ход"];
            case INVALID_MOVE_DIALOG_MESSAGE:
                return ["Server has refused to process your move. Please try again", "Ход, сделанный вами, не прошел проверку сервера. Попробуйте снова"];

            case GAME_ENDED_DIALOG_TITLE:
                return ["Game over", "Игра окончена"];

            case LIVE_WATCHING_LABEL_TEXT(watchedPlayerLogin):
                return ['Watching $watchedPlayerLogin', 'Наблюдение за $watchedPlayerLogin'];
            case LIVE_WATCHING_LABEL_TOOLTIP:
                return ["You follow this player. Each time he/she starts a new game, you'll be automatically redirected to watch it. To unfollow, simply leave this screen.", "Вы наблюдаете за этим игроком. Если игрок начнет новую игру, вы автоматически последуете за ним. Чтобы прекратить наблюдение, просто покиньте этот экран"];

            case SPECTATOR_COUNT_HEADER(cnt):
                return ['Spectating: $cnt', 'Наблюдателей: $cnt'];
            case FULL_SPECTATOR_LIST_DIALOG_TITLE:
                return ["All spectators", "Все наблюдатели"];

            case INPUT_PLAYER_LOGIN:
                return ["Input player's username", "Введите ник игрока"];

            case STUDY_PARAMS_DIALOG_CREATE_TITLE:
                return ["Save Study", "Сохранить студию"];
            case STUDY_PARAMS_DIALOG_EDIT_TITLE:
                return ["Edit Study Parameters", "Изменить параметры студии"];
        
            case STUDY_PARAMS_DIALOG_PARAM_NAME:
                return ["Name: ", "Название: "];
            case STUDY_PARAMS_DIALOG_PARAM_ACCESS:
                return ["Access: ", "Доступ: "];
            case STUDY_PARAMS_DIALOG_PARAM_DESCRIPTION(textCharsLimit):
                return ['Description (max $textCharsLimit chars):', 'Описание (до $textCharsLimit символов):'];
            case STUDY_PARAMS_DIALOG_PARAM_TAGS(tagCntLimit):
                return ['Tags (up to $tagCntLimit):', 'Теги (не более $tagCntLimit):'];
        
            case STUDY_PARAMS_DIALOG_ACCESS_OPTION(Public):
                return ["Public", "Публичный"];
            case STUDY_PARAMS_DIALOG_ACCESS_OPTION(DirectOnly):
                return ["From profile only", "Только из профиля"];
            case STUDY_PARAMS_DIALOG_ACCESS_OPTION(Private):
                return ["Private", "Приватный"];
            
            case STUDY_PARAMS_DIALOG_TAG_LIST_PREPENDER:
                return ["", ""];
            case STUDY_PARAMS_DIALOG_NO_TAGS_PLACEHOLDER:
                return ["<no tags>", "<нет>"];
            case STUDY_PARAMS_DIALOG_ADD_TAG_BUTTON_TOOLTIP:
                return ["Add", "Добавить"];
            case STUDY_PARAMS_DIALOG_REMOVE_TAG_BUTTON_TOOLTIP:
                return ["Remove", "Убрать"];
            case STUDY_PARAMS_DIALOG_CLEAR_TAGS_BUTTON_TOOLTIP:
                return ["Clear", "Очистить"];
            case STUDY_PARAMS_DIALOG_TAG_PROMPT_QUESTION:
                return ["Input tag:", "Введите тег:"];
        
            case STUDY_PARAMS_DIALOG_CREATE_BUTTON_TEXT:
                return ["Create Study", "Создать студию"];
            case STUDY_PARAMS_DIALOG_OVERWRITE_BUTTON_TEXT(overwrittenStudyName):
                return ['Overwrite $overwrittenStudyName', 'Перезаписать $overwrittenStudyName'];
            case STUDY_PARAMS_DIALOG_CREATE_AS_NEW_BUTTON_TEXT:
                return ["Create New Study", "Создать новую студию"];
            case STUDY_PARAMS_DIALOG_SAVE_CHANGES_BUTTON_TEXT:
                return ["Save Changes", "Сохранить изменения"];
            case STUDY_PARAMS_DIALOG_CANCEL_BUTTON_TEXT:
                return ["Cancel", "Отмена"];

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
                return ["Failed to accept challenge: the challenge was cancelled", "Не удалось принять вызов: вызов был отменен"];
            case INCOMING_CHALLENGE_ACCEPT_ERROR_SERVER_SHUTDOWN:
                return ["Failed to accept challenge: server is restarting", "Не удалось принять вызов: сервер перезапускается"];

            case SEND_DIRECT_CHALLENGE_SUCCESS_DIALOG_TITLE:
                return ["Challenge sent!", "Вызов отправлен!"];
            case SEND_DIRECT_CHALLENGE_SUCCESS_DIALOG_TEXT(opponentRef):
                switch opponentRef.concretize() 
                {
                    case Normal(login):
                        return ['Your challenge has been successfully sent to $login. You may cancel it at any time using the challenge menu at the top-right corner of your screen.', 'Вызов успешно отправлен игроку $login. Чтобы отменить его, воспользуйтесь меню вызовов в правом верхнем углу экрана.'];
                    default:
                        return ['Your challenge has been successfully sent. You may cancel it at any time using the challenge menu at the top-right corner of your screen.', 'Вызов успешно отправлен. Чтобы отменить его, воспользуйтесь меню вызовов в правом верхнем углу экрана.'];    
                }
            case SEND_OPEN_CHALLENGE_SUCCESS_DIALOG_TITLE:
                return ["Challenge created!", "Вызов создан!"];
            case SEND_OPEN_CHALLENGE_SUCCESS_DIALOG_TEXT:
                return ["Your open challenge has been created. To invite your friends directly, you may send them the link below. To cancel the challenge or to copy this link once again, use the challenge menu at the top-right corner of your screen.", "Ваш открытый вызов создан. Чтобы пригласить друзей напрямую, отправьте им ссылку ниже. Вы в любой момент можете отменить вызов или заново скопировать ссылку на него, воспользовавшись меню вызовов в правом верхнем углу экрана."];
            case SEND_CHALLENGE_ERROR_DIALOG_TITLE:
                return ["Challenge Creation Error", "Ошибка создания вызова"];
            case SEND_CHALLENGE_ERROR_TO_ONESELF:
                return ["Failed to create challenge: cannot send challenge to oneself", "Не удалось создать вызов: вызов не может быть адресован самому себе"];
            case SEND_CHALLENGE_ERROR_NOT_FOUND:
                return ["Failed to create challenge: player not found", "Не удалось создать вызов: игрок не найден"];
            case SEND_CHALLENGE_ERROR_ALREADY_EXISTS:
                return ["Failed to create challenge: you have already sent another challenge to this player. To create a new challenge, you should cancel the previous one first", "Не удалось создать вызов: вызов, адресованный данному игроку уже существует. Для создания нового вызова, сперва отмените предыдущий"];
            case SEND_CHALLENGE_ERROR_DUPLICATE:
                return ["Failed to create challenge: you have already created another similar challenge", "Не удалось создать вызов: вы уже создавали подобный вызов"];
            case SEND_CHALLENGE_ERROR_REMATCH_EXPIRED:
                return ["Failed to create challenge: rematch time has expired. Create a new challenge instead", "Не удалось создать вызов: время на предложение реванша истекло. Создайте новый вызов"];
            case SEND_CHALLENGE_ERROR_IMPOSSIBLE:
                return ["Failed to create challenge: impossible challenge. Please try again", "Не удалось создать вызов: невозможный вызов. Попробуйте снова"];
            case SEND_CHALLENGE_ERROR_SERVER_SHUTDOWN:
                return ["Server is restarting. Creating new challenges is disabled until the restart is complete. Please try later", "Сервер перезапускается. Создание новых вызовов отключено до завершения перезапуска. Попробуйте позже"];
            case CHALLENGE_PARAMS_DIALOG_TITLE:
                return ["Challenge Parameters", "Параметры Вызова"];
            case CHALLENGE_PARAMS_TYPE_OPTION_NAME:
                return ["Type", "Тип"];
            case CHALLENGE_PARAMS_TYPE_DIRECT:
                return ["Direct", "Прямой"];
            case CHALLENGE_PARAMS_TYPE_OPEN:
                return ["Open", "Открытый"];
            case CHALLENGE_PARAMS_TYPE_BOT:
                return ["Versus Bot", "Против компьютера"];
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
            case REQUESTS_FOLLOW_PLAYER_SUCCESS_DIALOG_TEXT:
                return ["You started following this player. Whenever he/she starts a new game, you will become the spectator automatically", "Теперь вы отслеживаете этого игрока. Когда он начнет партию, вы будете автоматически добавлены в число наблюдателей"];
            case REQUESTS_FOLLOW_PLAYER_SUCCESS_DIALOG_TITLE:
                return ["Success", "Успех"];
            case TURN_COLOR(White):
                return ["White to move", "Ход белых"];
            case TURN_COLOR(Black):
                return ["Black to move", "Ход черных"];
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

            case SPECTATOR_JOINED_MESSAGE(displayName):
                return ['$displayName is now spectating', '$displayName стал наблюдателем'];
            case SPECTATOR_LEFT_MESSAGE(displayName):
                return ['$displayName stopped spectating', '$displayName прекратил наблюдение'];

            case OPENING_STARTING_POSITION:
                return ["Starting position", "Начальная позиция"];
            case OPENING_UNORTHODOX_STARTING_POSITION:
                return ["Unorthodox starting position", "Нестандартная начальная позиция"];
            case OPENING_UNORTHODOX_LINE:
                return ["Unorthodox line", "Нестандартная линия"];

            case OLD_GAME_DATETIME:
                return ["Before 17.01.2023", "Ранее 17.01.2023"];

            case RESIGN_BTN_ABORT_TOOLTIP:
                return ["Abort", "Прервать"];
            case REMATCH_BTN_TOOLTIP:
                return ["Rematch", "Реванш"];
            case EXPLORE_IN_ANALYSIS_BTN_TOOLTIP:
                return ["Explore on analysis board", "На доску анализа"];
            case PREV_BTN_TOOLTIP:
                return ["Previous move", "Предыдущий ход"];
            case NEXT_BTN_TOOLTIP:
                return ["Next move", "Следующий ход"];
            case ADD_TIME_BTN_TOOLTIP:
                return ["Add time", "Добавить время"];
            case PLAY_FROM_POS_BTN_TOOLTIP:
                return ["Play from here", "Доиграть отсюда"];
            case VIEW_REPORT_BTN_TOOLTIP:
                return ["View Report", "Отчет о партии"];
            case OPEN_CHAT_BTN_TOOLTIP:
                return ["Chat", "Чат"];
            case OPEN_BRANCHING_BTN_TOOLTIP:
                return ["Branching", "Ветви"];
            case OPEN_GAME_INFO_BTN_TOOLTIP:
                return ["Game info", "Информация об игре"];
            case OPEN_SPECIAL_CONTROL_SETTINGS_TOOLTIP:
                return ["Special control settings", "Особые настройки управления"];

            case CHAT_SUBSCREEN_NAME:
                return ["Chat", "Чат"];
            case BRANCHING_SUBSCREEN_NAME:
                return ["Branching", "Ветви"];
            case GAME_INFO_SUBSCREEN_NAME:
                return ["Game info", "Об игре"];
            case SPECIAL_CONTROL_SETTINGS_SUBSCREEN_NAME:
                return ["Controls", "Управление"];

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

            case OFFER_ACTION_MESSAGE(Draw, sentBy, Create):
                if (sentBy != null)
                    return ['${Utils.getColorName(sentBy, EN)} offered a draw', '${Utils.getColorName(sentBy, RU)} предлагают ничью'];
                else
                    return ['Draw offered', 'Ничья предложена'];
            case OFFER_ACTION_MESSAGE(Draw, _, Cancel):
                return ["Draw request cancelled", "Предложение ничьи отменено"];
            case OFFER_ACTION_MESSAGE(Draw, _, Accept):
                return ["Draw accepted", "Ничья принята"];
            case OFFER_ACTION_MESSAGE(Draw, _, Decline):
                return ["Draw declined", "Ничья отклонена"];
                
            case OFFER_ACTION_MESSAGE(Takeback, sentBy, Create):
                if (sentBy != null)
                    return ['${Utils.getColorName(sentBy, EN)} requested a takeback', '${Utils.getColorName(sentBy, RU)} запросили возврат хода'];
                else
                    return ['Takeback requested', 'Возврат хода запрошен'];
            case OFFER_ACTION_MESSAGE(Takeback, _, Cancel):
                return ["Takeback cancelled", "Запрос возврата хода отменен"];
            case OFFER_ACTION_MESSAGE(Takeback, _, Accept):
                return ["Takeback accepted", "Возврат хода принят"];
            case OFFER_ACTION_MESSAGE(Takeback, _, Decline):
                return ["Takeback declined", "Возврат хода отклонен"];

            case PLAYER_DISCONNECTED_MESSAGE(color):
                return ['${Utils.getColorName(color, EN)} disconnected', '${Utils.getColorName(color, RU)} отключились'];
            case PLAYER_RECONNECTED_MESSAGE(color):
                return ['${Utils.getColorName(color, EN)} reconnected', '${Utils.getColorName(color, RU)} переподключились'];
            case TIME_ADDED_MESSAGE(receiverColor):
                var secsAdded:Int = Math.round(Constants.msAddedByOpponent / 1000);
                return ['${Utils.getColorName(receiverColor, EN)}: +$secsAdded seconds', '${Utils.getColorName(receiverColor, RU)}: +$secsAdded секунд'];
            case ABORT_CONFIRMATION_MESSAGE:
                return ["Are you sure you want to abort the game?", "Вы уверены, что хотите прервать игру?"];

            case CONNECTION_LOST_ERROR:
                return ["Connection lost", "Потеряно соединение"];
            case CONNECTION_ERROR_DIALOG_TITLE:
                return ["Connection error", "Ошибка подключения"];
            case SERVER_ERROR_DIALOG_TITLE:
                return ["Server error", "Ошибка сервера"];
            case SERVER_ERROR_DIALOG_TEXT(errorMessage):
                return ['A server error occured while processing your request. Details:\n$errorMessage', 'Во время исполнения вашего запроса возникла серверная ошибка. Подробности:\n$errorMessage'];

            case SERVER_UNAVAILABLE_DIALOG_TEXT:
                return ["Failed to connect to the server. You may use the analysis board while the server is unreachable. Once the connection is restored, the upper menu will become active", "Не удалось подключиться к серверу. На время переподключения открыта доска анализа. Верхнее меню станет вновь активным, когда подключение восстановится"];
            case SERVER_UNAVAILABLE_DIALOG_TITLE:
                return ["Server unavailable", "Сервер недоступен"];
            case SESSION_CLOSED_ALERT_TITLE:
                return ["Connection Closed", "Соединение закрыто"];
            case SESSION_CLOSED_ALERT_TEXT:
                return ["Connection was closed. Either you logged from another tab, browser or device or you were inactive for too long. Reload the page to reconnect", "Соединение было разорвано. Либо вы подключились из другой вкладки, из другого браузера или с другого устройства, либо же вы были неактивны слишком долго. Перезагрузите страницу для переподключения"];
            case RECONNECTION_POP_UP_TEXT:
                return ["Reconnecting...", "Восстанавливаем соединение..."];
            case RECONNECTION_POP_UP_TITLE:
                return ["Connection lost", "Потеряно соединение"];

            case SERVER_IS_SHUTTING_DOWN_WARNING_TITLE:
                return ["Server is shutting down", "Сервер перезапускается"];
            case SERVER_IS_SHUTTING_DOWN_WARNING_TEXT:
                return ["Server is restarting. Challenges are disabled until the restart is complete.", "Сервер перезапускается. Вызовы отключены до окончания перезагрузки."];

            case OUTDATED_CLIENT_ERROR_TITLE:
                return ["Outdated client", "Клиент устарел"];
            case OUTDATED_CLIENT_ERROR_TEXT:
                return ["Outdated client. Try forceful reload (Ctrl+F5). If a problem persists, please contact the administrator (Telegram: @gulvan).", "Клиент устарел. Попробуйте перезагрузить страницу с очисткой кэша (Ctrl+F5). Если проблема сохраняется, пожалуйста, сообщите администратору (Telegram: @gulvan)."];
            case OUTDATED_SERVER_ERROR_TITLE:
                return ["Outdated server", "Сервер устарел"];
            case OUTDATED_SERVER_ERROR_TEXT:
                return ["Outdated server. Please contact the administrator (Telegram: @gulvan).", "Сервер устарел. Пожалуйста, сообщите администратору (Telegram: @gulvan)."];

            case CLIPBOARD_ERROR_ALERT_TITLE:
                return ["Clipboard Error", "Ошибка буфера обмена"];
            case CLIPBOARD_ERROR_ALERT_TEXT:
                return ["Failed to copy: $0", "Копирование не удалось: $0"];

            case CORRESPONDENCE_TIME_CONTROL_NAME:
                return ["Correspondence", "По переписке"];

            case NOTIFICATION_BROWSER_TAB_TITLE(notification):
                return switch notification 
                {
                    case IncomingChallenge: ["New Challenge!", "Новый вызов!"];
                    case GameStarted: ["Game Started!", "Игра началась!"];
                }
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