package gfx.screens;

import gfx.game.common.PanelName;
import gfx.game.common.ComponentPageName;
import gfx.game.behaviours.NormalAnalysis;
import gfx.game.interfaces.IBehaviour;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.models.ReadOnlyModel;
import net.shared.dataobj.ViewedScreen;
import net.shared.dataobj.StudyInfo;
import dict.Phrase;
import gfx.game.models.AnalysisBoardModel;

class Analysis extends GenericGameScreen 
{
    private var model:AnalysisBoardModel;

	public function getTitle():Null<Phrase> 
    {
        var exploredStudyInfo:StudyInfo = model.exploredStudyInfo;
        if (exploredStudyInfo == null)
		    return ANALYSIS_BOARD_NO_STUDY_SCREEN_TITLE;
        else
            return STUDY_SCREEN_TITLE(exploredStudyInfo.id, exploredStudyInfo.name);
	}

	public function getURLPath():Null<String> 
    {
		var exploredStudyInfo:StudyInfo = model.exploredStudyInfo;
        if (exploredStudyInfo == null)
		    return 'analysis';
        else
            return 'study/${exploredStudyInfo.id}';
	}

	public function getPage():ViewedScreen 
    {
		return Analysis;
	}

	private function customOnEnter() 
    {
        //* Do nothing
    }

	private function customOnClose() 
    {
        //* Do nothing
    }

	private function getModel():ReadOnlyModel 
    {
		return AnalysisBoard(model);
	}

	private function processModelUpdateAtTopLevel(update:ModelUpdateEvent) 
    {
        switch update 
        {
            case EditorModeUpdated:
                setPageHidden(PositionEditor, model.editorMode == null);
            default:
        }
    }

    public function new(model:AnalysisBoardModel)
    {
        super();
        this.model = model;

        var initialBehaviour:IBehaviour = new NormalAnalysis(model);

        var panelMap:Map<PanelName, Array<ComponentPageName>> = [
            LargeBoardBox => [Board],
            LargeExtras => [PositionEditor],
            LargeLeft => [],
            LargeRight => [AnalysisOverview, Branching],
            CompactBoardBox => [Board],
            CompactExtras => [PositionEditor],
            CompactTop => [CreepingLine],
            CompactBottom => [CompactAnalysisActionBar]
        ];

        var subscreenNames:Array<ComponentPageName> = [Branching];

        init(initialBehaviour, panelMap, subscreenNames);
        setPageHidden(PositionEditor, model.editorMode == null);
    }
}