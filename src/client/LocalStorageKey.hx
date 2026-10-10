package client;

enum abstract LocalStorageKey(String) from String to String
{
    var TOKEN:String = "session.token";
    var IDENTITY:String = "session.identity";
    var REMEMBER_ME:String = "session.saved_credentials.remember_me";
    var SAVED_LOGIN:String = "session.saved_credentials.login";
    var SAVED_PASSWORD:String = "session.saved_credentials.password";
    var CHALLENGE_MARKS:String = "challenges.marks";
    var REDIRECTED_GAME_ID:String = "challenges.redirected_game_id";
    var SEEN_INCOMING_CHALLENGE_IDS:String = "challenges.seen_incoming_ids";
}
