package client.logic.games;

import client.datatypes.games.Condition;
import client.datatypes.games.PlayerValue;

enum ImplicitRestriction
{
    ExcludesCorrespondence;
    ExcludesUnrated;
    /** Only the games the player took part in **/
    OnlyGamesOf(player:PlayerValue);
    ExcludesOngoing;
}

/** What a condition excludes besides what it tests, in the games subject to it, even under NOT **/
class ImplicitRestrictions
{
    public static function of(condition:Condition):Array<ImplicitRestriction>
    {
        var restrictions:Array<ImplicitRestriction> = [];

        switch condition.property
        {
            case INITIAL_TIME | BONUS_TIME | TIME_LEFT:
                restrictions.push(ExcludesCorrespondence);
            case ELO | ELO_PROVISIONAL:
                restrictions.push(ExcludesUnrated);
            case ENDED_AT:
                restrictions.push(ExcludesOngoing);
            default:
        }

        switch [condition.property, condition.parameter]
        {
            case [TIME_LEFT | ELO | ELO_PROVISIONAL, OfPlayer(player)]:
                restrictions.push(OnlyGamesOf(player));
            default:
        }

        return restrictions;
    }
}
