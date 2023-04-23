package gfx.live.models;

import gfx.live.interfaces.IReadOnlyGenericModel;
import gfx.live.interfaces.IReadOnlyGameRelatedModel;
import net.shared.EloValue;
import net.shared.utils.PlayerRef;
import net.shared.board.RawPly;
import net.shared.Outcome;
import utils.TimeControl;
import gfx.live.interfaces.IReadOnlyMsRemainders;
import net.shared.dataobj.TimeReservesData;
import net.shared.board.Situation;
import net.shared.PieceColor;

class CommonModelExtractors
{
    public static function asGameModel(genericModel:ReadOnlyModel):Null<IReadOnlyGameRelatedModel>
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model), MatchVersusBot(model), Spectation(model):
                model;
            case AnalysisBoard(model):
                null;
        }
    }

    public static function asGenericModel(genericModel:ReadOnlyModel):IReadOnlyGenericModel
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model), MatchVersusBot(model), Spectation(model), AnalysisBoard(model):
                model;
        }
    }

    public static function getLastPlyInfo(genericModel:IReadOnlyGenericModel):{ply:RawPly, situationBefore:Situation}
    {
        var line = genericModel.getLine();
        var lastMoveIndex = genericModel.getLineLength() - 1;
        var secondToLastMoveIndex = lastMoveIndex - 1;

        return {ply: line[lastMoveIndex].ply, situationBefore: line[secondToLastMoveIndex].situationAfter};
    }

    public static function getLastChatEntry(genericModel:IReadOnlyGameRelatedModel):Null<ChatEntry>
    {
        var history:Array<ChatEntry> = genericModel.getChatHistory();

        if (!Lambda.empty(history))
            return history[history.length - 1];
        else
            return null;
    }

    public static function getColorByRef(genericModel:IReadOnlyGameRelatedModel, ref:PlayerRef):Null<PieceColor>
    {
        var whiteRef = genericModel.getPlayerRef(White);
        var blackRef = genericModel.getPlayerRef(Black);

        if (whiteRef == null || blackRef == null)
            return null;

        if (whiteRef.equals(ref))
            return White;
        else if (blackRef.equals(ref))
            return Black;
        else
            return null;
    }
}