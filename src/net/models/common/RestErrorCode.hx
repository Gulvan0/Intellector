package net.models.common;

enum abstract RestErrorCode(String) from String to String
{
    var USER_NOT_FOUND = "user_not_found";
    var INVALID_CREDENTIALS = "invalid_credentials";
    var USER_ALREADY_EXISTS = "user_already_exists";
    var CALLEE_NOT_FOUND = "callee_not_found";
    var CHALLENGE_ALREADY_EXISTS = "challenge_already_exists";
    var TOO_MANY_ACTIVE_CHALLENGES = "too_many_active_challenges";
    var TOO_MANY_DIRECT_CHALLENGES = "too_many_direct_challenges";
    var SERVER_RESTARTING = "server_restarting";
}
