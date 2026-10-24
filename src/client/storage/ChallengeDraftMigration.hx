package client.storage;

import client.datatypes.challenge.creation.CalleeKind;
import client.datatypes.challenge.creation.CallerColorChoice;
import client.datatypes.challenge.creation.ChallengeDraft;
import client.datatypes.challenge.creation.ChallengeType;
import client.datatypes.challenge.creation.OpenChallengeVisibility;
import client.datatypes.challenge.creation.StartingPositionMode;
import haxefolio.HaxeFolioApp;
import intellectorboard.mappers.Sip;
import js.Cookie;

/**
    Carries the previous version's `lastChallengeParams` cookie over to the challenge draft in
    localStorage: `startSecs;bonusSecs;type;acceptorColor;startingSituation;rated`, where type is
    `p` (public), `l` (link only), `+<bot handle>` or the callee ref (`_<id>` for a guest).
**/
class ChallengeDraftMigration
{
    private static inline final COOKIE_NAME:String = "lastChallengeParams";
    private static inline final GUEST_REF_PREFIX:String = "_";

    public static function run():Void
    {
        var rawValue:Null<String> = Cookie.get(COOKIE_NAME);

        if (rawValue == null)
            return;

        Cookie.remove(COOKIE_NAME);

        // a draft saved by this version is newer than the cookie
        if (HaxeFolioApp.valueStorage.read(LocalStorageKey.CHALLENGE_DRAFT_TYPE) != null)
            return;

        var draft:Null<ChallengeDraft> = parse(rawValue);

        if (draft != null)
            ChallengeDraftStorage.save(draft);
    }

    private static function parse(rawValue:String):Null<ChallengeDraft>
    {
        var parts:Array<String> = rawValue.split(";");

        if (parts.length != 6)
            return null;

        var startSeconds:Null<Int> = Std.parseInt(parts[0]);
        var incrementSeconds:Null<Int> = Std.parseInt(parts[1]);

        if (startSeconds == null || incrementSeconds == null)
            return null;

        var draft:ChallengeDraft = new ChallengeDraft();

        if (startSeconds > 0)
        {
            draft.startSeconds = startSeconds;
            draft.incrementSeconds = incrementSeconds;
        }
        else
            draft.timed = false;

        applyType(draft, parts[2]);

        // the cookie holds the colour of the one who accepts, the draft that of the one who creates
        draft.callerColor = switch parts[3] {
            case "w": CallerColorChoice.BLACK;
            case "b": CallerColorChoice.WHITE;
            default: CallerColorChoice.RANDOM;
        }

        if (parts[4] != "" && new Sip(parts[4]).toPosition() != null)
        {
            draft.positionMode = StartingPositionMode.CUSTOM;
            draft.customSip = parts[4];
        }

        draft.rated = parts[5] == "t";

        return draft;
    }

    private static function applyType(draft:ChallengeDraft, typeCode:String):Void
    {
        switch typeCode
        {
            case "p":
                draft.type = ChallengeType.OPEN;
                draft.visibility = OpenChallengeVisibility.PUBLIC;
            case "l":
                draft.type = ChallengeType.OPEN;
                draft.visibility = OpenChallengeVisibility.LINK_ONLY;
            default:
                if (typeCode.charAt(0) == "+") // the bot handle isn't kept: bot challenges have no form fields yet
                    return;

                draft.type = ChallengeType.DIRECT;

                if (typeCode.charAt(0) == GUEST_REF_PREFIX)
                {
                    draft.calleeKind = CalleeKind.GUEST;
                    draft.calleeGuestNumber = typeCode.substr(1);
                }
                else
                    draft.calleeLogin = typeCode;
        }
    }
}
