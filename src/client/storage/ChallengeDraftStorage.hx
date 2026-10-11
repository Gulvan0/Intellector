package client.storage;

import client.datatypes.challenge.creation.CalleeKind;
import client.datatypes.challenge.creation.CallerColorChoice;
import client.datatypes.challenge.creation.ChallengeDraft;
import client.datatypes.challenge.creation.ChallengeType;
import client.datatypes.challenge.creation.OpenChallengeVisibility;
import client.datatypes.challenge.creation.StartingPositionMode;
import haxefolio.HaxeFolioApp;

/**
    The challenge creation form's last submitted values in localStorage, one key per value. A missing
    or unreadable value reads as the form's default.
**/
class ChallengeDraftStorage
{
    public static function read():ChallengeDraft
    {
        var draft:ChallengeDraft = new ChallengeDraft();

        draft.type = readChoice(LocalStorageKey.CHALLENGE_DRAFT_TYPE, [ChallengeType.DIRECT, ChallengeType.OPEN, ChallengeType.BOT], draft.type);
        draft.visibility = readChoice(LocalStorageKey.CHALLENGE_DRAFT_VISIBILITY, [OpenChallengeVisibility.PUBLIC, OpenChallengeVisibility.LINK_ONLY], draft.visibility);
        draft.calleeKind = readChoice(LocalStorageKey.CHALLENGE_DRAFT_CALLEE_KIND, [CalleeKind.PLAYER, CalleeKind.GUEST], draft.calleeKind);
        draft.calleeLogin = HaxeFolioApp.valueStorage.read(LocalStorageKey.CHALLENGE_DRAFT_CALLEE_LOGIN) ?? draft.calleeLogin;
        draft.calleeGuestNumber = HaxeFolioApp.valueStorage.read(LocalStorageKey.CHALLENGE_DRAFT_CALLEE_GUEST_NUMBER) ?? draft.calleeGuestNumber;
        draft.timed = readBool(LocalStorageKey.CHALLENGE_DRAFT_TIMED, draft.timed);
        draft.startSeconds = readInt(LocalStorageKey.CHALLENGE_DRAFT_START_SECONDS, draft.startSeconds);
        draft.incrementSeconds = readInt(LocalStorageKey.CHALLENGE_DRAFT_INCREMENT_SECONDS, draft.incrementSeconds);
        draft.rated = readBool(LocalStorageKey.CHALLENGE_DRAFT_RATED, draft.rated);
        draft.callerColor = readChoice(LocalStorageKey.CHALLENGE_DRAFT_CALLER_COLOR, [CallerColorChoice.WHITE, CallerColorChoice.RANDOM, CallerColorChoice.BLACK], draft.callerColor);
        draft.positionMode = readChoice(LocalStorageKey.CHALLENGE_DRAFT_POSITION_MODE, [StartingPositionMode.DEFAULT, StartingPositionMode.CUSTOM], draft.positionMode);
        draft.customSip = HaxeFolioApp.valueStorage.read(LocalStorageKey.CHALLENGE_DRAFT_CUSTOM_SIP);

        return draft;
    }

    public static function save(draft:ChallengeDraft):Void
    {
        HaxeFolioApp.valueStorage.write(LocalStorageKey.CHALLENGE_DRAFT_TYPE, draft.type);
        HaxeFolioApp.valueStorage.write(LocalStorageKey.CHALLENGE_DRAFT_VISIBILITY, draft.visibility);
        HaxeFolioApp.valueStorage.write(LocalStorageKey.CHALLENGE_DRAFT_CALLEE_KIND, draft.calleeKind);
        HaxeFolioApp.valueStorage.write(LocalStorageKey.CHALLENGE_DRAFT_CALLEE_LOGIN, draft.calleeLogin);
        HaxeFolioApp.valueStorage.write(LocalStorageKey.CHALLENGE_DRAFT_CALLEE_GUEST_NUMBER, draft.calleeGuestNumber);
        HaxeFolioApp.valueStorage.write(LocalStorageKey.CHALLENGE_DRAFT_TIMED, Std.string(draft.timed));
        HaxeFolioApp.valueStorage.write(LocalStorageKey.CHALLENGE_DRAFT_START_SECONDS, Std.string(draft.startSeconds));
        HaxeFolioApp.valueStorage.write(LocalStorageKey.CHALLENGE_DRAFT_INCREMENT_SECONDS, Std.string(draft.incrementSeconds));
        HaxeFolioApp.valueStorage.write(LocalStorageKey.CHALLENGE_DRAFT_RATED, Std.string(draft.rated));
        HaxeFolioApp.valueStorage.write(LocalStorageKey.CHALLENGE_DRAFT_CALLER_COLOR, draft.callerColor);
        HaxeFolioApp.valueStorage.write(LocalStorageKey.CHALLENGE_DRAFT_POSITION_MODE, draft.positionMode);

        if (draft.customSip != null)
            HaxeFolioApp.valueStorage.write(LocalStorageKey.CHALLENGE_DRAFT_CUSTOM_SIP, draft.customSip);
        else
            HaxeFolioApp.valueStorage.remove(LocalStorageKey.CHALLENGE_DRAFT_CUSTOM_SIP);
    }

    private static function readChoice<T:String>(key:LocalStorageKey, allowed:Array<T>, fallback:T):T
    {
        var stored:Null<String> = HaxeFolioApp.valueStorage.read(key);

        for (value in allowed)
            if (value == stored)
                return value;

        return fallback;
    }

    private static function readBool(key:LocalStorageKey, fallback:Bool):Bool
    {
        return switch HaxeFolioApp.valueStorage.read(key) {
            case "true": true;
            case "false": false;
            default: fallback;
        }
    }

    private static function readInt(key:LocalStorageKey, fallback:Int):Int
    {
        var stored:Null<String> = HaxeFolioApp.valueStorage.read(key);
        var parsed:Null<Int> = stored != null ? Std.parseInt(stored) : null;
        return parsed ?? fallback;
    }
}
