package client.storage;

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
    var CHALLENGE_DRAFT_TYPE:String = "challenge_draft.type";
    var CHALLENGE_DRAFT_VISIBILITY:String = "challenge_draft.visibility";
    var CHALLENGE_DRAFT_CALLEE_KIND:String = "challenge_draft.callee_kind";
    var CHALLENGE_DRAFT_CALLEE_LOGIN:String = "challenge_draft.callee_login";
    var CHALLENGE_DRAFT_CALLEE_GUEST_NUMBER:String = "challenge_draft.callee_guest_number";
    var CHALLENGE_DRAFT_TIMED:String = "challenge_draft.timed";
    var CHALLENGE_DRAFT_START_SECONDS:String = "challenge_draft.start_seconds";
    var CHALLENGE_DRAFT_INCREMENT_SECONDS:String = "challenge_draft.increment_seconds";
    var CHALLENGE_DRAFT_RATED:String = "challenge_draft.rated";
    var CHALLENGE_DRAFT_CALLER_COLOR:String = "challenge_draft.caller_color";
    var CHALLENGE_DRAFT_POSITION_MODE:String = "challenge_draft.position_mode";
    var CHALLENGE_DRAFT_CUSTOM_SIP:String = "challenge_draft.custom_sip";
}
