package engine.hxconda.protocol;

import engine.hxconda.board.Move;
import engine.hxconda.search.BestMoveReport;

class HxcondaProtocol
{
    /** Null if nothing has been recorded **/
    public static function reportMessage(report:BestMoveReport):Null<HxcondaReportMessage>
    {
        if (!report.isSet)
            return null;

        var message:HxcondaReportMessage = {
            move: report.move == Move.NONE ? null : moveMessage(report.move),
            score: report.score,
            depth: report.depth,
            searchedRootMoveCount: report.searchedRootMoveCount
        };
        if (report.principalLine != null)
            message.principalLine = report.principalLine.map(moveMessage);
        return message;
    }

    public static function decodeResponse(response:HxcondaResponse):HxcondaEvent
    {
        return switch response.kind {
            case Progress: HxcondaEvent.Progress(response.percent);
            case Iteration: HxcondaEvent.Iteration(response.report);
            case Completed: HxcondaEvent.Completed(response.report);
            case Failed: HxcondaEvent.Failed(response.error);
        }
    }

    private static function moveMessage(move:Move):HxcondaMoveMessage
    {
        return {from: move.from, to: move.to, resultingPiece: move.resultingPiece};
    }
}
