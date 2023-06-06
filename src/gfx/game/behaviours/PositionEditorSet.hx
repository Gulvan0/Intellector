package gfx.game.behaviours;

import net.shared.board.Hex;
import gfx.game.events.GameboardEvent;
import gfx.game.models.AnalysisBoardModel;

class PositionEditorSet extends AnalysisRelatedBehaviour 
{
    private var hex:Hex;

    public function handleGameboardEvent(event:GameboardEvent)
    {
        switch event 
        {
            case HexSelected(coords):
                model.editorSituation.set(coords, hex);
                modelUpdateHandler(EditorSituationUpdated);
                model.deriveShownSituationFromOtherParams();
                modelUpdateHandler(ShownSituationUpdated);
            default:
        }
    }

    public function new(model:AnalysisBoardModel, hex:Hex)
    {
        super(model);
        this.hex = hex;
    }    
}