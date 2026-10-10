package client.datatypes;

/** A user action whose request failed, as named in the failure notice **/
enum abstract FailedAction(String) from String to String
{
    var ACCEPT_CHALLENGE = "accept_challenge";
    var DECLINE_CHALLENGE = "decline_challenge";
    var CANCEL_CHALLENGE = "cancel_challenge";
    var OPEN_STARTED_GAME = "open_started_game";
}
