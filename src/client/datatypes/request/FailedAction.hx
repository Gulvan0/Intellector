package client.datatypes.request;

/** A user action whose request failed, as named in the failure notice **/
enum abstract FailedAction(String) from String to String
{
    var ACCEPT_CHALLENGE = "accept_challenge";
    var DECLINE_CHALLENGE = "decline_challenge";
    var CANCEL_CHALLENGE = "cancel_challenge";
    var OPEN_STARTED_GAME = "open_started_game";
    var CREATE_CHALLENGE = "create_challenge";
    var LOAD_GAME = "load_game";
    var MAKE_MOVE = "make_move";
    var OFFER_DRAW = "offer_draw";
    var CANCEL_DRAW = "cancel_draw";
    var ANSWER_DRAW = "answer_draw";
    var OFFER_TAKEBACK = "offer_takeback";
    var CANCEL_TAKEBACK = "cancel_takeback";
    var ANSWER_TAKEBACK = "answer_takeback";
    var RESIGN = "resign";
    var ADD_TIME = "add_time";
    var SEND_CHAT_MESSAGE = "send_chat_message";
    var FOLLOW_PLAYER = "follow_player";
    var UNFOLLOW_PLAYER = "unfollow_player";
}
