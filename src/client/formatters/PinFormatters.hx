package client.formatters;

import client.datatypes.game.GameEnding;
import client.datatypes.game.LiveGameInfo;
import client.datatypes.game.Outcome;
import intellectorboard.mappers.notation.GamePinFormatter;
import intellectorboard.primitives.ply.RawPly;

/** A game's record in PIN, the same in every locale **/
class PinFormatters
{
    public static function pin(info:LiveGameInfo, plies:Array<RawPly>, ending:Null<GameEnding>):String
    {
        var timeControl:Null<String> = switch info.timeControl {
            case None: null;
            case Fischer(instance): TimeControlFormatters.formatFischerTimeControl(instance);
        }
        var startedAt:Null<Date> = info.startedAtMs != null ? Date.fromTime(info.startedAtMs) : null;

        return GamePinFormatter.format(
            info.startingPosition,
            plies,
            info.white.nickname,
            info.black.nickname,
            timeControl,
            startedAt,
            outcomeLine(ending)
        );
    }

    /** `1-0 (Fatum)`, `1/2-1/2 (Threefold repetition)`; `-` for an aborted game, `*` for one still going **/
    public static function outcomeLine(ending:Null<GameEnding>):String
    {
        if (ending == null)
            return "*";

        return switch ending.outcome {
            case Decisive(kind, winner): '${winner == White ? "1-0" : "0-1"} (${decisiveReason(kind)})';
            case Drawish(Abort): "-";
            case Drawish(kind): '1/2-1/2 (${drawishReason(kind)})';
        }
    }

    private static function decisiveReason(kind:DecisiveOutcomeKind):String
    {
        return switch kind {
            case Mate: "Fatum";
            case Breakthrough: "Breakthrough";
            case Timeout: "Timeout";
            case Resign: "Resignation";
            case Abandon: "Abandonment";
            case CheatingAbort: "Disqualification";
        }
    }

    private static function drawishReason(kind:DrawishOutcomeKind):String
    {
        return switch kind {
            case DrawAgreement: "Agreement";
            case Repetition: "Threefold repetition";
            case NoProgress: "Sixty-move rule";
            case Abort: "Aborted";
        }
    }
}
