package gfx.live.models;

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
    public static function getOrientation(genericModel:ReadOnlyModel):PieceColor
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getOrientation();
            case MatchVersusBot(model):
                model.getOrientation();
            case Spectation(model):
                model.getOrientation();
            case AnalysisBoard(model):
                model.getOrientation();
        }
    }

    public static function getShownSituation(genericModel:ReadOnlyModel):Situation
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getShownSituation();
            case MatchVersusBot(model):
                model.getShownSituation();
            case Spectation(model):
                model.getShownSituation();
            case AnalysisBoard(model):
                model.getShownSituation();
        }
    }

    public static function getCurrentSituation(genericModel:ReadOnlyModel):Situation
    {
        switch genericModel 
        {
            case MatchVersusPlayer(model):
                return model.getCurrentSituation();
            case MatchVersusBot(model):
                return model.getCurrentSituation();
            case Spectation(model):
                return model.getCurrentSituation();
            case AnalysisBoard(model):
                return model.getSituationAtLineEnd();
        }
    }

    public static function getBoardInteractivityMode(genericModel:ReadOnlyModel):InteractivityMode
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getBoardInteractivityMode();
            case MatchVersusBot(model):
                model.getBoardInteractivityMode();
            case Spectation(model):
                model.getBoardInteractivityMode();
            case AnalysisBoard(model):
                model.getBoardInteractivityMode();
        }
    }

    public static function getChatHistory(genericModel:ReadOnlyModel):Array<ChatEntry>
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getChatHistory();
            case MatchVersusBot(model):
                model.getChatHistory();
            case Spectation(model):
                model.getChatHistory();
            case AnalysisBoard(model):
                [];
        }
    }

    public static function getLastChatEntry(genericModel:ReadOnlyModel):Null<ChatEntry>
    {
        var history:Array<ChatEntry> = getChatHistory(genericModel);

        if (!Lambda.empty(history))
            return history[history.length - 1];
        else
            return null;
    }

    public static function gameEnded(genericModel:ReadOnlyModel):Null<Bool>
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.hasEnded();
            case MatchVersusBot(model):
                model.hasEnded();
            case Spectation(model):
                model.hasEnded();
            case AnalysisBoard(model):
                null;
        }
    }

    public static function playerColor(genericModel:ReadOnlyModel):Null<PieceColor>
    {
        switch genericModel 
        {
            case MatchVersusPlayer(model):
                if (LoginManager.isPlayer(model.getPlayerRef(White)))
                    return White;
                else
                    return Black;
            case MatchVersusBot(model):
                if (LoginManager.isPlayer(model.getPlayerRef(White)))
                    return White;
                else
                    return Black;
            case Spectation(model):
                return null;
            case AnalysisBoard(model):
                return null;
        }
    }

    public static function activeTimerColor(genericModel:ReadOnlyModel):Null<PieceColor>
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getActiveTimerColor();
            case MatchVersusBot(model):
                model.getActiveTimerColor();
            case Spectation(model):
                model.getActiveTimerColor();
            case AnalysisBoard(model):
                null;
        }
    }

    public static function timeData(genericModel:ReadOnlyModel):Null<TimeReservesData>
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getTimeReservesData();
            case MatchVersusBot(model):
                model.getTimeReservesData();
            case Spectation(model):
                model.getTimeReservesData();
            case AnalysisBoard(model):
                null;
        }
    }

    public static function getMsRemainders(genericModel:ReadOnlyModel):IReadOnlyMsRemainders
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getMsRemainders();
            case MatchVersusBot(model):
                model.getMsRemainders();
            case Spectation(model):
                model.getMsRemainders();
            case AnalysisBoard(model):
                null;
        }
    }

    public static function getLineLength(genericModel:ReadOnlyModel):Int
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getHistory().getMoveCount();
            case MatchVersusBot(model):
                model.getHistory().getMoveCount();
            case Spectation(model):
                model.getHistory().getMoveCount();
            case AnalysisBoard(model):
                model.getSelectedBranch().length;
        }
    }

    public static function getShownMovePointer(genericModel:ReadOnlyModel):Int
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getShownMove();
            case MatchVersusBot(model):
                model.getShownMove();
            case Spectation(model):
                model.getShownMove();
            case AnalysisBoard(model):
                model.getShownMovePointer();
        }
    }

    public static function getTimeControl(genericModel:ReadOnlyModel):Null<TimeControl>
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getTimeControl();
            case MatchVersusBot(model):
                model.getTimeControl();
            case Spectation(model):
                model.getTimeControl();
            case AnalysisBoard(model):
                null;
        }
    }

    public static function getOutcome(genericModel:ReadOnlyModel):Null<Outcome>
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getOutcome();
            case MatchVersusBot(model):
                model.getOutcome();
            case Spectation(model):
                model.getOutcome();
            case AnalysisBoard(model):
                null;
        }
    }

    public static function getLine(genericModel:ReadOnlyModel):Array<{incomingPly:RawPly, situation:Situation}>
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getStartingSituation();
            case MatchVersusBot(model):
                model.getStartingSituation();
            case Spectation(model):
                model.getStartingSituation();
            case AnalysisBoard(model):
                model.getVariation().getFullMainline(false, model.getSelectedBranch()).map(x -> {incomingPly: x.getIncomingPly(), situation: x.getSituation()});
        }
    }

    public static function getStartingSituation(genericModel:ReadOnlyModel):Situation
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getStartingSituation();
            case MatchVersusBot(model):
                model.getStartingSituation();
            case Spectation(model):
                model.getStartingSituation();
            case AnalysisBoard(model):
                model.getVariation().rootNode().getSituation();
        }
    }

    public static function getPlayerRef(genericModel:ReadOnlyModel, color:PieceColor):Null<PlayerRef>
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getPlayerRef(color);
            case MatchVersusBot(model):
                model.getPlayerRef(color);
            case Spectation(model):
                model.getPlayerRef(color);
            case AnalysisBoard(model):
                null;
        }
    }

    public static function getELO(genericModel:ReadOnlyModel, color:PieceColor):Null<EloValue>
    {
        return switch genericModel 
        {
            case MatchVersusPlayer(model):
                model.getELO(color);
            case MatchVersusBot(model):
                null;
            case Spectation(model):
                model.getELO(color);
            case AnalysisBoard(model):
                null;
        }
    }

    public static function getColorByRef(genericModel:ReadOnlyModel, ref:PlayerRef):Null<PieceColor>
    {
        var whiteRef = getPlayerRef(genericModel, White);
        var blackRef = getPlayerRef(genericModel, Black);

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