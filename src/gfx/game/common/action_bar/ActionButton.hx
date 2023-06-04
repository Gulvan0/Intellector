package gfx.game.common.action_bar;

import dict.Phrase;

enum ActionButtonInternal
{
    Resign;
    Abort;
    ChangeOrientation;
    OfferDraw;
    CancelDraw;
    OfferTakeback;
    CancelTakeback;
    AddTime;
    Rematch;
    Share;
    PlayFromHere;
    Analyze;
    PrevMove;
    NextMove;
    EditPosition;
    ViewReport;
    OpenChat;
    OpenBranching;
    OpenSpecialControlSettings;
    OpenGameInfo;
}

abstract ActionButton(ActionButtonInternal) from ActionButtonInternal to ActionButtonInternal
{
    public function unwrap():ActionButtonInternal 
    {
        return this;    
    }

    public function equals(btn:ActionButton)
    {
        return this == btn.unwrap();
    }

    public function iconPath():String 
    {
        return switch this 
        {
            case Resign: "assets/images/game/common/action_bar/resign.svg";
            case Abort: "assets/images/game/common/action_bar/abort_game.svg";
            case ChangeOrientation: "assets/images/game/common/flip.svg";
            case OfferDraw: "assets/images/game/common/action_bar/offer_draw.svg";
            case CancelDraw: "assets/images/game/common/action_bar/cancel_offer.svg";
            case OfferTakeback: "assets/images/game/common/action_bar/takeback.svg";
            case CancelTakeback: "assets/images/game/common/action_bar/cancel_offer.svg";
            case AddTime: "assets/images/game/common/action_bar/add_time.svg";
            case Rematch: "assets/images/game/common/action_bar/rematch.svg";
            case Share: "assets/images/game/common/action_bar/share.svg";
            case PlayFromHere: "assets/images/game/common/action_bar/play_from_pos.svg";
            case Analyze: "assets/images/game/common/action_bar/analyze.svg";
            case PrevMove: "assets/images/game/common/prev.svg";
            case NextMove: "assets/images/game/common/next.svg";
            case EditPosition: "assets/images/common/edit.svg";
            case ViewReport: "assets/images/game/common/action_bar/report.svg";
            case OpenChat: "assets/images/game/common/action_bar/chat.svg";
            case OpenBranching: "assets/images/game/common/action_bar/branching.svg";
            case OpenSpecialControlSettings: "assets/images/game/common/action_bar/special_settings.svg";
            case OpenGameInfo: "assets/images/game/common/action_bar/gameinfo.svg";
        }
    }

    public function tooltip():Phrase
    {
        return switch this 
        {
            case Resign: RESIGN_BTN_TOOLTIP;
            case Abort: RESIGN_BTN_ABORT_TOOLTIP;
            case ChangeOrientation: CHANGE_ORIENTATION_BTN_TOOLTIP;
            case OfferDraw: OFFER_DRAW_BTN_TOOLTIP;
            case CancelDraw: CANCEL_DRAW_BTN_TOOLTIP;
            case OfferTakeback: TAKEBACK_BTN_TOOLTIP;
            case CancelTakeback: CANCEL_TAKEBACK_BTN_TOOLTIP;
            case AddTime: ADD_TIME_BTN_TOOLTIP;
            case Rematch: REMATCH_BTN_TOOLTIP;
            case Share: LIVE_SHARE_BTN_TOOLTIP;
            case PlayFromHere: PLAY_FROM_POS_BTN_TOOLTIP;
            case Analyze: EXPLORE_IN_ANALYSIS_BTN_TOOLTIP;
            case PrevMove: PREV_BTN_TOOLTIP;
            case NextMove: NEXT_BTN_TOOLTIP;
            case EditPosition: ANALYSIS_SET_POSITION_BTN_TOOLTIP;
            case ViewReport: VIEW_REPORT_BTN_TOOLTIP;
            case OpenChat: OPEN_CHAT_BTN_TOOLTIP;
            case OpenBranching: OPEN_BRANCHING_BTN_TOOLTIP;
            case OpenSpecialControlSettings: OPEN_GAME_INFO_BTN_TOOLTIP;
            case OpenGameInfo: OPEN_SPECIAL_CONTROL_SETTINGS_TOOLTIP;
        }
    }

    public function confirmation():Null<Phrase>
    {
        return switch this 
        {
            case Resign: RESIGN_CONFIRMATION_MESSAGE;
            case Abort: ABORT_CONFIRMATION_MESSAGE;
            default: null;
        }
    }
}