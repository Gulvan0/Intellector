package gfx.game.models;

import net.shared.utils.UnixTimestamp;
import net.shared.dataobj.TimeReservesData;
import gfx.game.interfaces.IReadOnlyMsRemainders;
import gfx.game.interfaces.IReadOnlyGenericModel;
import gfx.game.interfaces.IReadOnlyGameRelatedModel;
import net.shared.utils.PlayerRef;
import net.shared.board.RawPly;
import net.shared.board.Situation;
import net.shared.PieceColor;

class CommonModelExtractors
{
    public static function asGameModel(genericModel:ReadOnlyModel):Null<IReadOnlyGameRelatedModel>
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model): model;
            case MatchVersusBot(model): model;
            case Spectation(model): model;
            case AnalysisBoard(_): null;
        }
    }

    public static function asGenericModel(genericModel:ReadOnlyModel):IReadOnlyGenericModel
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model): model;
            case MatchVersusBot(model): model;
            case Spectation(model): model;
            case AnalysisBoard(model): model;
        }
    }

    public static function mutableGenericToReadOnly(mutableModel:Model):ReadOnlyModel
    {
        return switch mutableModel 
        {
            case MatchVersusPlayer(model): MatchVersusPlayer(model);
            case MatchVersusBot(model): MatchVersusBot(model);
            case Spectation(model): Spectation(model);
            case AnalysisBoard(model): AnalysisBoard(model);
        }
    }

    public static function getPlannedPremoves(genericModel:ReadOnlyModel):Array<RawPly>
    {
        switch genericModel 
        {
            case MatchVersusPlayer(model): 
                return model.getPlannedPremoves();
            case MatchVersusBot(model): 
                return model.getPlannedPremoves();
            default:
                throw 'getPlannedPremoves() call is only valid for either MatchVersusPlayer or MatchVersusBot model. Got: ${genericModel?.getName()}';
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

    public static function getActualSecsLeft(genericModel:IReadOnlyGameRelatedModel, side:PieceColor):Null<{secs:Float, calculatedAt:UnixTimestamp}>
    {
        var remainders:Null<IReadOnlyMsRemainders> = genericModel.getMsRemainders();

        if (remainders == null)
            return null;

        var nowTimestamp:UnixTimestamp = UnixTimestamp.now();

        if (genericModel.hasEnded())
            return {secs: remainders.getTimeLeftWhenEnded().getSecsLeftAtTimestamp(side), calculatedAt: nowTimestamp};

        var actualTimeData:TimeReservesData = remainders.getTimeLeftAfterMove(genericModel.getLineLength());
        var secsLeftAtTimestamp:Float = actualTimeData.getSecsLeftAtTimestamp(side);


        if (genericModel.getActiveTimerColor() != side)
            return {secs: secsLeftAtTimestamp, calculatedAt: nowTimestamp};
        else
            return {secs: Math.max(secsLeftAtTimestamp - actualTimeData.timestamp.getIntervalSecsTo(nowTimestamp), 0), calculatedAt: nowTimestamp};
    }

    public static function isPlayerParticipant(genericModel:IReadOnlyGameRelatedModel):Bool
    {
        return getColorByRef(genericModel, LoginManager.getRef()) != null;
    }
}