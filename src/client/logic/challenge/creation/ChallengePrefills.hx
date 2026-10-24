package client.logic.challenge.creation;

import client.datatypes.challenge.creation.ChallengeDraft;
import client.datatypes.challenge.creation.ChallengeType;
import client.datatypes.game.LiveGameInfo;
import client.datatypes.timecontrol.FischerTimeControl;
import intellectorboard.mappers.Sip;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;

/**
    Ready-made adjustments to the remembered challenge draft, for the places that open the challenge
    creation form with some of its values already decided
**/
class ChallengePrefills
{
    /** The same game again against the same opponent, with the colours swapped **/
    public static function rematch(draft:ChallengeDraft, game:LiveGameInfo, userColor:PieceColor):Void
    {
        var opponentRef:String = game.participant(userColor.opposite()).ref;

        draft.type = DIRECT;

        if (StringTools.startsWith(opponentRef, "_"))
        {
            draft.calleeKind = GUEST;
            draft.calleeGuestNumber = opponentRef.substr(1);
        }
        else
        {
            draft.calleeKind = PLAYER;
            draft.calleeLogin = opponentRef;
        }

        switch game.timeControl
        {
            case None:
                draft.timed = false;
            case Fischer(instance):
                draft.timed = true;
                draft.startSeconds = instance.startSeconds;
                draft.incrementSeconds = instance.incrementSeconds;
        }

        draft.rated = game.rated;
        draft.callerColor = userColor == White ? BLACK : WHITE;

        if (game.customStartingPosition)
            startFrom(draft, game.startingPosition);
        else
            draft.positionMode = DEFAULT;
    }

    /** A new game starting from `position`; unrated unless it is the default one **/
    public static function playFrom(draft:ChallengeDraft, position:Position):Void
    {
        if (position.isDefaultStarting())
        {
            draft.positionMode = DEFAULT;
            return;
        }

        draft.rated = false;
        startFrom(draft, position);
    }

    /** A timed game with `timeControl`, the other values as remembered **/
    public static function timeControl(draft:ChallengeDraft, timeControl:FischerTimeControl):Void
    {
        draft.timed = true;
        draft.startSeconds = timeControl.startSeconds;
        draft.incrementSeconds = timeControl.incrementSeconds;
    }

    public static function versusBot(draft:ChallengeDraft):Void
    {
        draft.type = BOT;
    }

    private static function startFrom(draft:ChallengeDraft, position:Position):Void
    {
        draft.positionMode = CUSTOM;
        draft.customSip = Sip.fromPosition(position);
    }
}
