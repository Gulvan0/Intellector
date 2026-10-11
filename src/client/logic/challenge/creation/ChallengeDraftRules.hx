package client.logic.challenge.creation;

import client.datatypes.challenge.creation.CalleeInput;
import client.datatypes.challenge.creation.CallerColorChoice;
import client.datatypes.challenge.creation.ChallengeDraft;
import client.datatypes.challenge.creation.ChallengeParams;
import client.datatypes.challenge.creation.ChallengeTarget;
import client.datatypes.challenge.creation.StartingPositionMode;
import intellectorboard.mappers.Sip;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;

/**
    What a challenge draft means: the constraints its values put on each other, and the challenge it
    describes. A rated game has a random colour and the default position; a guest only plays
    unrated. A constrained value is kept in the draft as chosen, so lifting the constraint restores it.
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
    }

    public static function effectiveCallerColor(draft:ChallengeDraft):CallerColorChoice
    {
        return draft.rated ? RANDOM : draft.callerColor;
    }

    public static function effectivePositionMode(draft:ChallengeDraft):StartingPositionMode
    {
        return draft.rated ? DEFAULT : draft.positionMode;
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
            case BOT: Bot;
        }
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

        return new ChallengeParams(target, ChallengeTimeControlRules.timeControl(draft), draft.rated, callerColor, customStartingPosition(draft));
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
