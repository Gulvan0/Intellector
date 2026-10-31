package client.logic.challenge.creation;

import client.datatypes.bot.BotKind;
import client.datatypes.bot.BotSettings;
import client.datatypes.challenge.creation.CalleeInput;
import client.datatypes.challenge.creation.CallerColorChoice;
import client.datatypes.challenge.creation.ChallengeDraft;
import client.datatypes.challenge.creation.ChallengeParams;
import client.datatypes.challenge.creation.ChallengeTarget;
import client.datatypes.challenge.creation.StartingPositionMode;
import client.logic.bot.BotStrengthRules;
import client.logic.bot.BotThinkCapRules;
import intellectorboard.mappers.Sip;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;

/**
    What a challenge draft means: the constraints its values put on each other, and the challenge it
    describes. A rated game has a random colour and the default position; a guest and a bot only
    play unrated. A constrained value is kept in the draft as chosen, so lifting the constraint
    restores it.
**/
class ChallengeDraftRules
{
    /** Brings a remembered draft in line with what the user opening the form may create **/
    public static function normalize(draft:ChallengeDraft, isGuest:Bool):Void
    {
        if (isGuest)
            draft.rated = false;

        if (draft.customSip != null)
        {
            var position:Null<Position> = parseSip(draft.customSip);
            if (position == null || !position.isValidStarting())
                draft.customSip = null;
        }

        if (draft.bot != null && !BotStrengthRules.isAvailable(draft.bot, draft.botStrength))
            draft.botStrength = Std.int(Math.max(BotStrengthRules.MIN_STRENGTH, Math.min(draft.botStrength, BotStrengthRules.maxStrength(draft.bot))));
    }

    /** Picks `kind`, bringing the strength down to the strongest it plays at if needed **/
    public static function selectBot(draft:ChallengeDraft, kind:BotKind):Void
    {
        draft.bot = kind;
        if (draft.botStrength > BotStrengthRules.maxStrength(kind))
            draft.botStrength = BotStrengthRules.maxStrength(kind);
    }

    /** Whether the game is rated: never against a bot **/
    public static function effectiveRated(draft:ChallengeDraft):Bool
    {
        return draft.rated && draft.type != BOT;
    }

    public static function effectiveCallerColor(draft:ChallengeDraft):CallerColorChoice
    {
        return effectiveRated(draft) ? RANDOM : draft.callerColor;
    }

    public static function effectivePositionMode(draft:ChallengeDraft):StartingPositionMode
    {
        return effectiveRated(draft) ? DEFAULT : draft.positionMode;
    }

    /** The position the game starts from, or null for the default one **/
    public static function customStartingPosition(draft:ChallengeDraft):Null<Position>
    {
        if (effectivePositionMode(draft) == DEFAULT || draft.customSip == null)
            return null;

        var position:Null<Position> = parseSip(draft.customSip);
        return position != null && !position.isDefaultStarting() ? position : null;
    }

    public static function startingPosition(draft:ChallengeDraft):Position
    {
        return customStartingPosition(draft) ?? Position.defaultStarting();
    }

    /** `ownUserRef`: the current user's, never a valid callee **/
    public static function calleeInput(draft:ChallengeDraft, ownUserRef:Null<String>):CalleeInput
    {
        return switch draft.calleeKind {
            case PLAYER: CalleeParsing.parseLogin(draft.calleeLogin, ownUserRef);
            case GUEST: CalleeParsing.parseGuestNumber(draft.calleeGuestNumber, ownUserRef);
        }
    }

    /** Who the challenge goes to, or null while the draft doesn't name a valid callee **/
    public static function target(draft:ChallengeDraft, ownUserRef:Null<String>):Null<ChallengeTarget>
    {
        return switch draft.type {
            case DIRECT: validTarget(calleeInput(draft, ownUserRef));
            case OPEN: draft.visibility == PUBLIC ? Public : LinkOnly;
            case BOT: botTarget(draft);
        }
    }

    /** The bot the draft names, or null while it names none or its settings are invalid **/
    public static function botTarget(draft:ChallengeDraft):Null<ChallengeTarget>
    {
        var kind:Null<BotKind> = draft.bot;
        if (kind == null || !BotStrengthRules.isAvailable(kind, draft.botStrength))
            return null;
        if (draft.botCapEnabled && !BotThinkCapRules.isValid(draft.botCapSeconds))
            return null;

        return Bot(new BotSettings(kind, draft.botStrength, draft.botCapEnabled ? draft.botCapSeconds : null));
    }

    /** The challenge the draft describes, or null while any value it needs is invalid **/
    public static function params(draft:ChallengeDraft, ownUserRef:Null<String>):Null<ChallengeParams>
    {
        var target:Null<ChallengeTarget> = target(draft, ownUserRef);

        if (target == null || !ChallengeTimeControlRules.isValid(draft))
            return null;

        var callerColor:Null<PieceColor> = switch effectiveCallerColor(draft) {
            case WHITE: White;
            case BLACK: Black;
            default: null;
        }

        return new ChallengeParams(target, ChallengeTimeControlRules.timeControl(draft), effectiveRated(draft), callerColor, customStartingPosition(draft));
    }

    /** `sip` as a position, or null if it isn't well-formed **/
    public static function parseSip(sip:String):Null<Position>
    {
        try
        {
            return new Sip(StringTools.trim(sip)).toPosition();
        }
        catch (_)
        {
            return null; // a malformed SIP may break the parser rather than make it return null
        }
    }

    private static function validTarget(input:CalleeInput):Null<ChallengeTarget>
    {
        return switch input {
            case Valid(target): target;
            default: null;
        }
    }
}
