package client.datatypes.games;

import client.datatypes.game.Outcome.DecisiveOutcomeKind;
import client.datatypes.game.Outcome.DrawishOutcomeKind;
import client.datatypes.timecontrol.TimeControlKind;

/** One of the values a sole equality condition accepts **/
enum EqualityValue
{
    /** `player`, `winner` **/
    IsPlayer(player:PlayerValue);
    /** `winner`: none yet **/
    IsOngoing;
    /** `winner`: no one **/
    IsDraw;
    IsTimeControlKind(kind:TimeControlKind);
    /** `rated`, `elo_provisional` **/
    IsBool(value:Bool);
    IsDecisiveOutcome(kind:DecisiveOutcomeKind);
    IsDrawishOutcome(kind:DrawishOutcomeKind);
    IsDefaultPosition;
    IsCustomPosition(sip:String);
    /** By the opening's stable id **/
    IsOpening(id:Int);
    IsResult(result:ResultKind);
}
