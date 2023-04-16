package gfx.live.models;

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
                var variation = model.getVariation();
                var selectedPath = model.getSelectedNodePath();
                var lastMainlineNodePath = variation.getFullMainlinePath(selectedPath);
                return variation.getNode(lastMainlineNodePath).getSituation();
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
                model.getVariation().getFullMainlinePath(model.getSelectedNodePath()).length;
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
                model.getSelectedNodePath().length;
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
}