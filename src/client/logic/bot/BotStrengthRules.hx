package client.logic.bot;

import client.datatypes.bot.BotKind;
import engine.hxconda.search.weakening.Weakening;

/** Which strengths a bot may play at, and what a strength means for its search **/
class BotStrengthRules
{
    public static inline final MIN_STRENGTH:Int = 1;
    public static inline final MAX_STRENGTH:Int = 9;

    // Per strength from 1 to 8; MAX_STRENGTH always plays the best move
    private static final MIN_LOSSES:Array<Float> = [200, 100, 50, 25, 20, 10, 0, 0];
    /** Null: unbounded **/
    private static final MAX_LOSSES:Array<Null<Float>> = [null, 500, 300, 150, 100, 80, 45, 20];
    /** How many root moves inside its loss window the bot scores exactly to pick from **/
    private static inline final CANDIDATE_COUNT:Int = 3;

    /** How many of its own plies of a game the bot plays at its best before it starts weakening **/
    private static final BEST_PLY_COUNTS:Array<Int> = [0, 1, 2, 3, 4, 5, 6, 7];

    private static inline final MAX_STRENGTH_HALF_DEPTH:Int = 13;

    /** The strongest strength `kind` plays at: only Standard reaches `MAX_STRENGTH` **/
    public static function maxStrength(kind:BotKind):Int
    {
        return kind == STANDARD ? MAX_STRENGTH : MAX_STRENGTH - 1;
    }

    public static function isAvailable(kind:BotKind, strength:Int):Bool
    {
        return strength >= MIN_STRENGTH && strength <= maxStrength(kind);
    }

    /**
        How the bot picks its move after playing `ownPlyCount` plies of the game, losing centiprogressors on purpose;
        null while it plays its best
    **/
    public static function weakening(strength:Int, ownPlyCount:Int):Null<Weakening>
    {
        if (strength >= MAX_STRENGTH || ownPlyCount < BEST_PLY_COUNTS[strength - 1])
            return null;

        var weakening:Weakening = {
            minLoss: MIN_LOSSES[strength - 1],
            weightExponent: strength,
            candidateCount: CANDIDATE_COUNT,
            scoredFromDepth: strength >= 3 ? 8 : 6
        };
        var maxLoss:Null<Float> = MAX_LOSSES[strength - 1];
        if (maxLoss != null)
            weakening.maxLoss = maxLoss;
        return weakening;
    }

    /** Search depth, in full moves, chosen by the time a move takes **/
    public static function halfDepth(strength:Int):Int
    {
        return strength >= MAX_STRENGTH ? MAX_STRENGTH_HALF_DEPTH : strength + 2;
    }
}
