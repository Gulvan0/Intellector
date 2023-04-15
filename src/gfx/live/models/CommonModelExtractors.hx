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

    public static function getShownSituation(model:ReadOnlyModel):Situation
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

    public static function getBoardInteractivityMode(model:ReadOnlyModel):InteractivityMode
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
}