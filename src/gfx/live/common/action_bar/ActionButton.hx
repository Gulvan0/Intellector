package gfx.live.common.action_bar;

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
            case Resign: "assets/symbols/live/resign.svg";
            case Abort: "assets/symbols/live/abort_game.svg";
            case ChangeOrientation: "assets/symbols/analysis/flip.svg";
            case OfferDraw: "assets/symbols/live/offer_draw.svg";
            case CancelDraw: "assets/symbols/live/cancel_offer.svg";
            case OfferTakeback: "assets/symbols/live/takeback.svg";
            case CancelTakeback: "assets/symbols/live/cancel_offer.svg";
            case AddTime: "assets/symbols/live/add_time.svg";
            case Rematch: "assets/symbols/live/rematch.svg";
            case Share: "assets/symbols/common/share.svg";
            case PlayFromHere: "assets/symbols/common/play_from_pos.svg";
            case Analyze: "assets/symbols/live/analyze.svg";
            case PrevMove: "assets/symbols/common/prev.svg";
            case NextMove: "assets/symbols/common/next.svg";
            case EditPosition: "assets/symbols/common/edit.svg";
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
        }
    }
}