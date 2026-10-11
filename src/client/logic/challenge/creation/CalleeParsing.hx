package client.logic.challenge.creation;

import client.datatypes.challenge.creation.CalleeInput;
import client.datatypes.challenge.creation.ChallengeTarget;

/**
    Reads who a direct challenge is for from what the user typed. Logins always start with a Latin
    letter, so the login field also takes a guest, written as their number with an optional
    `#`, `_`, "Guest" or "Гость" in front.
**/
class CalleeParsing
{
    private static final LOGIN_PATTERN:EReg = ~/^[A-Za-z](_?[A-Za-z0-9]+)+$/;
    private static final GUEST_PATTERN:EReg = ~/^(guest|гость|#|_)?\s*#?\s*([0-9]+)$/i;
    private static final GUEST_NUMBER_PATTERN:EReg = ~/^[0-9]+$/;

    /** `ownUserRef`: the current user's, never a valid callee **/
    public static function parseLogin(text:String, ownUserRef:Null<String>):CalleeInput
    {
        var trimmed:String = StringTools.trim(text);

        if (trimmed.length == 0)
            return Empty;

        if (GUEST_PATTERN.match(trimmed))
            return guest(GUEST_PATTERN.matched(2), ownUserRef);

        if (!LOGIN_PATTERN.match(trimmed))
            return Invalid("invalid_login");

        if (trimmed == ownUserRef)
            return Invalid("self");

        return Valid(Player(trimmed));
    }

    public static function parseGuestNumber(text:String, ownUserRef:Null<String>):CalleeInput
    {
        var trimmed:String = StringTools.trim(text);

        if (trimmed.length == 0)
            return Empty;

        if (!GUEST_NUMBER_PATTERN.match(trimmed))
            return Invalid("digits_only");

        return guest(trimmed, ownUserRef);
    }

    private static function guest(digits:String, ownUserRef:Null<String>):CalleeInput
    {
        var guestId:Null<Int> = Std.parseInt(digits);

        if (guestId == null || guestId <= 0)
            return Invalid("above_zero");

        var target:ChallengeTarget = Guest(guestId);

        if (target.calleeRef() == ownUserRef)
            return Invalid("self");

        return Valid(target);
    }
}
