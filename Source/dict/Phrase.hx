package dict;

import net.shared.StudyPublicity;
import net.shared.EloValue;
import net.shared.UserStatus;
import net.shared.UserRole;
import net.shared.Outcome;
import net.shared.PieceColor;

enum Phrase
{
    LANGUAGE_NAME;

    //Analysis screen

    ANALYSIS_OVERVIEW_TAB_NAME;
    ANALYSIS_SET_POSITION_BTN_TOOLTIP;
    ANALYSIS_SHARE_BTN_TOOLTIP;
    
    ANALYSIS_BRANCHING_TAB_NAME;
    ANALYSIS_BRANCHING_HELP_LINK_TEXT;
    ANALYSIS_BRANCHING_HELP_DIALOG_TITLE;
    ANALYSIS_BRANCHING_HELP_DIALOG_TEXT;

    ANALYSIS_OPENINGS_TAB_NAME;
    ANALYSIS_OPENINGS_TEASER_TEXT;

    ANALYSIS_CLEAR_BTN_TOOLTIP;
    ANALYSIS_RESET_BTN_TOOLTIP;
    ANALYSIS_TO_STARTPOS_BTN_TOOLTIP;
    ANALYSIS_FLIP_BOARD_BTN_TOOLTIP;
    ANALYSIS_IMPORT_BTN_TOOLTIP;
    ANALYSIS_WHITE_TO_MOVE_OPTION_TEXT;
    ANALYSIS_BLACK_TO_MOVE_OPTION_TEXT;
    ANALYSIS_APPLY_CHANGES_BTN_TEXT;
    ANALYSIS_DISCARD_CHANGES_BTN_TEXT;

    ANALYSIS_INPUT_SIP_PROMPT_TEXT;
    ANALYSIS_INVALID_SIP_WARNING_TITLE;
    ANALYSIS_INVALID_SIP_WARNING_TEXT;

    //Share dialog

    SHARE_DIALOG_TITLE;

    SHARE_POSITION_TAB_NAME;
    SHARE_SIP_HEADER;
    SHARE_IMAGE_HEADER;
    SHARE_DOWNLOAD_PNG_BTN_TEXT;
    SHARE_DOWNLOAD_PNG_MARKUP_CHECKBOX_TEXT;
    SHARE_DOWNLOAD_PNG_DIMENSIONS_LABEL_TEXT;
    SHARE_DOWNLOAD_PNG_KEEP_RATIO_CHECKBOX_TEXT;
    SHARE_DOWNLOAD_PNG_BGCOLOR_LABEL_TEXT;
    SHARE_DOWNLOAD_PNG_TRANSPARENT_BG_CHECKBOX_TEXT;

    SHARE_GAME_TAB_NAME;
    SHARE_LINK_HEADER;
    SHARE_PIN_HEADER;
    SHARE_ANIMATED_GIF_HEADER;
    SHARE_DOWNLOAD_GIF_WIDTH_LABEL_TEXT;
    SHARE_DOWNLOAD_GIF_INTERVAL_LABEL_TEXT;
    SHARE_EXPORT_AND_DOWNLOAD_BTN_TEXT;

    SHARE_EXPORT_TAB_NAME;
    SHARE_EXPORT_AS_STUDY_HEADER;
    SHARE_EXPORT_AS_STUDY_BTN_TEXT;
    SHARE_EXPORT_AS_QUESTION_MARKS_TEASER;
    SHARE_COMING_SOON;

    //Open challenge joining

    OPENJOIN_CHALLENGE_BY_HEADER;
    OPENJOIN_COLOR_WHITE_OWNER;
    OPENJOIN_COLOR_BLACK_OWNER;
    OPENJOIN_COLOR_RANDOM;
    OPENJOIN_RATED;
    OPENJOIN_UNRATED;
    OPENJOIN_ACCEPT_BTN_TEXT;
    OPENJOIN_ESSENTIAL_PARAMS_LABEL_TEXT;

    //Menubar

    MENUBAR_PLAY_MENU_TITLE;
    MENUBAR_PLAY_MENU_CREATE_GAME_ITEM;
    MENUBAR_PLAY_MENU_OPEN_CHALLENGES_ITEM;
    
    MENUBAR_SPECTATE_MENU_TITLE;
    MENUBAR_SPECTATE_MENU_CURRENT_GAMES_ITEM;
    MENUBAR_SPECTATE_MENU_FOLLOW_PLAYER_ITEM;
    
    MENUBAR_LEARN_MENU_TITLE;
    MENUBAR_LEARN_MENU_ANALYSIS_BOARD_ITEM;
    
    MENUBAR_SOCIAL_MENU_TITLE;
    MENUBAR_SOCIAL_MENU_PLAYER_PROFILE_ITEM;

    MENUBAR_CHALLENGES_HEADER_INCOMING_CHALLENGE;
    MENUBAR_CHALLENGES_HEADER_OUTGOING_CHALLENGE;
    MENUBAR_CHALLENGES_FROM_LINE_TEXT;
    MENUBAR_CHALLENGES_TO_LINE_TEXT;
    MENUBAR_CHALLENGES_ACCEPT_BUTTON_TEXT;
    MENUBAR_CHALLENGES_DECLINE_BUTTON_TEXT;
    MENUBAR_CHALLENGES_CANCEL_BUTTON_TEXT;

    MENUBAR_ACCOUNT_MENU_LOGIN_ITEM;
    MENUBAR_ACCOUNT_MENU_MY_PROFILE_ITEM;
    MENUBAR_ACCOUNT_MENU_SETTINGS_ITEM;
    MENUBAR_ACCOUNT_MENU_LOGOUT_ITEM;
    MENUBAR_ACCOUNT_MENU_GUEST_DISPLAY_NAME;

    //Menubar dialogs

    CHANGELOG_DIALOG_TITLE;

    LOGIN_DIALOG_TITLE;
    LOGIN_LOG_IN_MODE_TITLE;
    LOGIN_REGISTER_MODE_TITLE;
    LOGIN_LOGIN_FIELD_NAME;
    LOGIN_PASSWORD_FIELD_NAME;
    LOGIN_REPEAT_PASSWORD_FIELD_NAME;
    LOGIN_REMEMBER_ME;
    LOGIN_REMAIN_LOGGED;
    
    LOGIN_WARNING_MESSAGEBOX_TITLE;
    LOGIN_INVALID_PASSWORD_WARNING_TEXT;
    LOGIN_PASSWORDS_DO_NOT_MATCH;
    LOGIN_ALREADY_REGISTERED_WARNING_TEXT;
    LOGIN_LOGIN_NOT_SPECIFIED_WARNING_TEXT;
    LOGIN_PASSWORD_NOT_SPECIFIED_WARNING_TEXT;
    LOGIN_REPEATED_PASSWORD_NOT_SPECIFIED_WARNING_TEXT;
    LOGIN_BAD_LOGIN_LENGTH_WARNING_TEXT;
    LOGIN_BAD_PASSWORD_LENGTH_WARNING_TEXT;

    SETTINGS_DIALOG_TITLE;
    SETTINGS_GENERAL_TAB_TITLE;
    SETTINGS_APPEARANCE_TAB_TITLE;
    SETTINGS_CONTROLS_TAB_TITLE;
    SETTINGS_INTEGRATIONS_TAB_TITLE;

    SETTINGS_LANGUAGE_OPTION_NAME;
    SETTINGS_MARKUP_OPTION_NAME;
    SETTINGS_PREMOVES_OPTION_NAME;
    SETTINGS_BRANCHING_TYPE_OPTION_NAME;
    SETTINGS_BRANCHING_SHOW_TURN_COLOR_OPTION_NAME;
    SETTINGS_SILENT_CHALLENGES_OPTION_NAME;

    SETTINGS_MARKUP_ALL_OPTION_VALUE;
    SETTINGS_MARKUP_LETTERS_OPTION_VALUE;
    SETTINGS_MARKUP_NONE_OPTION_VALUE;

    SETTINGS_BRANCHING_TYPE_TREE_OPTION_VALUE;
    SETTINGS_BRANCHING_TYPE_OUTLINE_OPTION_VALUE;
    SETTINGS_BRANCHING_TYPE_PLAIN_OPTION_VALUE;

    SETTINGS_DISABLED_OPTION_VALUE;
    SETTINGS_ENABLED_OPTION_VALUE;

    //Profile

    PROFILE_ROLE_TEXT(role:UserRole);

    PROFILE_STATUS_TEXT(status:UserStatus);

    PROFILE_QUICK_ACTION_SEND_CHALLENGE_TOOLTIP;
    PROFILE_QUICK_ACTION_FOLLOW_TOOLTIP;

    PROFILE_ACTION_ADD_FRIEND_TOOLTIP;
    PROFILE_ACTION_REMOVE_FRIEND_TOOLTIP;

    PROFILE_FRIENDS_PREPENDER;

    PROFILE_GAMES_TAB_TITLE;
    PROFILE_STUDIES_TAB_TITLE;
    PROFILE_ONGOING_MATCHES_TAB_TITLE;

    PROFILE_GAMES_TCFILTER_ALL_GAMES_OPTION_NAME;
    PROFILE_GAMES_TCFILTER_GAMECNT_LABEL_TEXT(cnt:Int);
    PROFILE_GAMES_TCFILTER_ELO_LABEL_TEXT(elo:EloValue);

    PROFILE_STUDY_TAG_LABELS_PREPENDER;
    PROFILE_STUDY_NO_TAGS_PLACEHOLDER;
    PROFILE_STUDY_EDIT_BTN_TOOLTIP;
    PROFILE_STUDY_REMOVE_BTN_TOOLTIP;
    PROFILE_LOAD_MORE_BTN_TEXT;

    PROFILE_ONGOING_RELOAD_BTN_TEXT;

    PROFILE_TAG_FILTERS_PREPENDER;
    PROFILE_TAG_NO_FILTERS_PLACEHOLDER_TEXT;
    PROFILE_REMOVE_TAG_FILTER_BTN_TOOLTIP;
    PROFILE_ADD_TAG_FILTER_BTN_TEXT;
    PROFILE_CLEAR_TAG_FILTERS_BTN_TEXT;
    PROFILE_TAG_FILTER_PROMPT_QUESTION_TEXT;

    //Mini-profile

    MINIPROFILE_DIALOG_TITLE(ownerLogin:String);

    MINIPROFILE_FOLLOW_BTN_TOOLTIP;
    MINIPROFILE_UNFOLLOW_BTN_TOOLTIP;
    MINIPROFILE_FRIEND_BTN_TOOLTIP;
    MINIPROFILE_UNFRIEND_BTN_TOOLTIP;
    MINIPROFILE_CHALLENGE_BTN_TOOLTIP;
    MINIPROFILE_TO_PROFILE_BTN_TOOLTIP;

    //Main menu

    MAIN_MENU_CREATE_GAME_BTN_TEXT;
    READ_FULL_CHANGELOG_TOOLTIP;

    TABLEVIEW_RELOAD_BTN_TEXT;
    TABLEVIEW_MODE_COLUMN_NAME;
    TABLEVIEW_TIME_COLUMN_NAME;
    TABLEVIEW_PLAYER_COLUMN_NAME;
    TABLEVIEW_PLAYERS_COLUMN_NAME;
    TABLEVIEW_BRACKET_COLUMN_NAME;
    TABLEVIEW_BRACKET_RANKED(rated:Bool);

    CURRENT_GAMES_TABLE_HEADER;
    PAST_GAMES_TABLE_HEADER;
    OPEN_CHALLENGES_TABLE_HEADER;

    CHALLENGE_COLOR_ICON_TOOLTIP(color:Null<PieceColor>);

    //Live Game

    GAME_ENDED_DIALOG_TITLE;

    LIVE_WATCHING_LABEL_TEXT(watchedPlayerLogin:String);
    LIVE_WATCHING_LABEL_TOOLTIP;

    //Dialogs

    INPUT_PLAYER_LOGIN;

    //StudyParamsDialog

    STUDY_PARAMS_DIALOG_CREATE_TITLE;
    STUDY_PARAMS_DIALOG_EDIT_TITLE;

    STUDY_PARAMS_DIALOG_PARAM_NAME;
    STUDY_PARAMS_DIALOG_PARAM_ACCESS;
    STUDY_PARAMS_DIALOG_PARAM_DESCRIPTION(textCharsLimit:Int);
    STUDY_PARAMS_DIALOG_PARAM_TAGS(tagCntLimit:Int);

    STUDY_PARAMS_DIALOG_ACCESS_OPTION(option:StudyPublicity);
    
    STUDY_PARAMS_DIALOG_TAG_LIST_PREPENDER;
    STUDY_PARAMS_DIALOG_NO_TAGS_PLACEHOLDER;
    STUDY_PARAMS_DIALOG_ADD_TAG_BUTTON_TOOLTIP;
    STUDY_PARAMS_DIALOG_REMOVE_TAG_BUTTON_TOOLTIP;
    STUDY_PARAMS_DIALOG_CLEAR_TAGS_BUTTON_TOOLTIP;
    STUDY_PARAMS_DIALOG_TAG_PROMPT_QUESTION;

    STUDY_PARAMS_DIALOG_CREATE_BUTTON_TEXT;
    STUDY_PARAMS_DIALOG_OVERWRITE_BUTTON_TEXT(overwrittenStudyName:String);
    STUDY_PARAMS_DIALOG_CREATE_AS_NEW_BUTTON_TEXT;
    STUDY_PARAMS_DIALOG_SAVE_CHANGES_BUTTON_TEXT;
    STUDY_PARAMS_DIALOG_CANCEL_BUTTON_TEXT;

    //Incoming direct challenge dialog

    INCOMING_CHALLENGE_DIALOG_TITLE;
    INCOMING_CHALLENGE_CHALLENGE_BY_LABEL_TEXT;
    INCOMING_CHALLENGE_ACCEPT_BTN_TEXT;
    INCOMING_CHALLENGE_DECLINE_BTN_TEXT;

    //AcceptChallenge error notification

    INCOMING_CHALLENGE_ACCEPT_ERROR_DIALOG_TITLE;
    INCOMING_CHALLENGE_ACCEPT_ERROR_CALLER_OFFLINE;
    INCOMING_CHALLENGE_ACCEPT_ERROR_CALLER_INGAME;
    INCOMING_CHALLENGE_ACCEPT_ERROR_CHALLENGE_CANCELLED;

    //SendChallenge error notification

    SEND_CHALLENGE_ERROR_DIALOG_TITLE;
    SEND_CHALLENGE_ERROR_TO_ONESELF;
    SEND_CHALLENGE_ERROR_NOT_FOUND;
    SEND_CHALLENGE_ERROR_ALREADY_EXISTS;

    //Challenge params dialog

    CHALLENGE_PARAMS_DIALOG_TITLE;

    CHALLENGE_PARAMS_TYPE_OPTION_NAME;
    CHALLENGE_PARAMS_TYPE_DIRECT;
    CHALLENGE_PARAMS_TYPE_OPEN;

    CHALLENGE_PARAMS_DIRECT_USERNAME_OPTION_NAME;

    CHALLENGE_PARAMS_OPEN_VISIBILITY;
    CHALLENGE_PARAMS_OPEN_VISIBILITY_ALL;
    CHALLENGE_PARAMS_OPEN_VISIBILITY_BY_LINK;
    CHALLENGE_PARAMS_OPEN_LINK_HEADER;
    
    CHALLENGE_PARAMS_TIME_CONTROL_OPTION_NAME;
    CHALLENGE_PARAMS_TIME_CONTROL_START_OPTION_NAME;
    CHALLENGE_PARAMS_TIME_CONTROL_INCREMENT_OPTION_NAME;
    CHALLENGE_PARAMS_TIME_CONTROL_MINS_APPENDIX;
    CHALLENGE_PARAMS_TIME_CONTROL_SECS_APPENDIX;
    CHALLENGE_PARAMS_TIME_CONTROL_CORRESPONDENCE_CHECK_NAME;

    CHALLENGE_PARAMS_RANKED_CHECK_NAME;
    CHALLENGE_PARAMS_RATED_ANY_ELO_CHECK_NAME;
    CHALLENGE_PARAMS_RATED_MAXDIFF_OPTION_NAME;

    CHALLENGE_PARAMS_COLOR_OPTION_NAME;
    CHALLENGE_PARAMS_COLOR_RANDOM;
    CHALLENGE_PARAMS_COLOR_WHITE;
    CHALLENGE_PARAMS_COLOR_BLACK;

    CHALLENGE_PARAMS_STARTPOS_OPTION_NAME;
    CHALLENGE_PARAMS_STARTPOS_DEFAULT;
    CHALLENGE_PARAMS_STARTPOS_CUSTOM;
    CHALLENGE_PARAMS_STARTPOS_SIP_OPTION_NAME;

    CHALLENGE_PARAMS_CONFIRM_BTN_TEXT;

    CHALLENGE_PARAMS_INVALID_SIP_WARNING_TEXT;
    CHALLENGE_PARAMS_INVALID_SIP_WARNING_TITLE;
    CHALLENGE_PARAMS_INVALID_STARTPOS_WARNING_TEXT;
    CHALLENGE_PARAMS_INVALID_STARTPOS_WARNING_TITLE;

    //Requests

    REQUESTS_ERROR_DIALOG_TITLE;
    REQUESTS_ERROR_CHALLENGE_NOT_FOUND;
    REQUESTS_ERROR_PLAYER_NOT_FOUND;
    REQUESTS_ERROR_STUDY_NOT_FOUND;
    REQUESTS_ERROR_PLAYER_OFFLINE;
    REQUESTS_ERROR_PLAYER_NOT_IN_GAME;

    //Common

    TURN_COLOR(color:PieceColor);

    CUSTOM_STARTING_POSITION;


    //Not sorted yet

    CHATBOX_MESSAGE_PLACEHOLDER;
    SPECTATOR_JOINED_MESSAGE(login:Null<String>);
    SPECTATOR_LEFT_MESSAGE(login:Null<String>);
    OPPONENT_DISCONNECTED_MESSAGE;
    OPPONENT_RECONNECTED_MESSAGE;
    DRAW_OFFERED_MESSAGE;
    DRAW_CANCELLED_MESSAGE;
    DRAW_ACCEPTED_MESSAGE;
    DRAW_DECLINED_MESSAGE;
    TAKEBACK_OFFERED_MESSAGE;
    TAKEBACK_CANCELLED_MESSAGE;
    TAKEBACK_ACCEPTED_MESSAGE;
    TAKEBACK_DECLINED_MESSAGE;

    OPENING_STARTING_POSITION;

    PROMOTION_DIALOG_TITLE;
    PROMOTION_DIALOG_QUESTION;

    CHAMELEON_DIALOG_TITLE;
    CHAMELEON_DIALOG_QUESTION;

    CHANGE_ORIENTATION_BTN_TOOLTIP;
    RESIGN_BTN_TOOLTIP;
    RESIGN_BTN_ABORT_TOOLTIP;
    RESIGN_CONFIRMATION_MESSAGE;
    ABORT_CONFIRMATION_MESSAGE;
    OFFER_DRAW_BTN_TOOLTIP;
    TAKEBACK_BTN_TOOLTIP;
    CANCEL_DRAW_BTN_TOOLTIP;
    CANCEL_TAKEBACK_BTN_TOOLTIP;
    DRAW_QUESTION_TEXT;
    TAKEBACK_QUESTION_TEXT;
    EXPLORE_IN_ANALYSIS_BTN_TOOLTIP;
    REMATCH_BTN_TOOLTIP;
    ADD_TIME_BTN_TOOLTIP;
    LIVE_SHARE_BTN_TOOLTIP;
    PLAY_FROM_POS_BTN_TOOLTIP;


    //Connection management

    CONNECTION_LOST_ERROR;
    CONNECTION_ERROR_DIALOG_TITLE;
    SESSION_CLOSED_ALERT_TITLE;
    SESSION_CLOSED_ALERT_TEXT;
    RECONNECTION_POP_UP_TEXT;
    RECONNECTION_POP_UP_TITLE;

    //Copy

    COPY_BTN_TOOLTIP;
    COPY_BTN_SUCCESS_TOOLTIP;

    CLIPBOARD_ERROR_ALERT_TITLE;
    CLIPBOARD_ERROR_ALERT_TEXT;

    //Special

    CORRESPONDENCE_TIME_CONTROL_NAME;
}