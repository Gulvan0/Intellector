package gfx.live.models;

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
}