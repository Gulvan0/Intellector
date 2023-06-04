package gfx.game.behaviours;

import gfx.game.events.GameboardEvent;
import gfx.game.models.AnalysisBoardModel;

class PositionEditorMove extends AnalysisRelatedBehaviour 
{
    public function handleGameboardEvent(event:GameboardEvent)
    {
        switch event 
        {
            case FreeMovePerformed(from, to):
                model.editorSituation.set(to, model.editorSituation.get(from));
                model.editorSituation.set(from, Empty);
                modelUpdateHandler(EditorSituationUpdated);
            default:
        }
    }

    public function new(model:AnalysisBoardModel)
    {
        super(model);
    }    
}