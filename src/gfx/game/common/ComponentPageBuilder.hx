package gfx.game.common;

import dict.Dictionary;
import dict.Phrase;
import haxe.ui.containers.VBox;
import haxe.ui.containers.Box;
import gfx.game.live.UCMABox;
import gfx.game.common.ply_history_view.MoveNavigator;
import gfx.game.analysis.BranchingBox;
import gfx.game.analysis.AnalysisActionBar;
import gfx.game.live.LiveActionBar;
import gfx.game.analysis.PositionEditor;
import gfx.game.common.ply_history_view.CreepingLine;
import gfx.game.live.Chatbox;
import gfx.game.live.SpectatorList;
import gfx.game.live.GameInfoBox;
import gfx.game.interfaces.IGameComponent;

class ComponentPageBuilder
{
    private final name:Phrase;
    private final autoWidth:Bool = false;
    private final autoHeight:Bool = false;
    private final components:Array<IGameComponent>;

    public function buildPage():Box
    {
        var page:VBox = new VBox();
        page.text = Dictionary.getPhrase(name);

        if (!autoWidth)
            page.percentWidth = 100;
        if (!autoHeight)
            page.percentHeight = 100;

        page.verticalAlign = 'center';
        page.horizontalAlign = 'center';

        for (component in components)
        {
            component.asComponent().verticalAlign = 'center';
            component.asComponent().horizontalAlign = 'center';
            page.addComponent(component.asComponent());
        }

        return page;
    }

    public function allComponents():Array<IGameComponent>
    {
        return components.copy();
    }

    private function wrap(comp:IGameComponent, percentWidth:Null<Float>, percentHeight:Null<Float>):IGameComponent
    {
        if (percentWidth != null)
            comp.asComponent().percentWidth = percentWidth;

        if (percentHeight != null)
            comp.asComponent().percentHeight = percentHeight;

        return comp;
    }
    
    public function new(pageName:ComponentPageName)
    {
        name = GAME_COMPONENT_PAGE_TITLE(pageName);

        switch pageName 
        {
            case LargeLeftPanelMain:
                components = [wrap(new GameInfoBox(), 100, null), wrap(new SpectatorList(), 100, null), wrap(new Chatbox(), 100, 100)];
            case UCMA:
                components = [wrap(new UCMABox(), 100, 100)];
            case AnalysisOverview:
                components = [wrap(new MoveNavigator(), 100, 100), wrap(new AnalysisActionBar(false), 100, null)];
            case Branching:
                components = [wrap(new BranchingBox(), 100, 100)];
            case PositionEditor:
                components = [wrap(new PositionEditor(), 100, 100)];
            case Board:
                components = [wrap(new GameBoardWrapper(), 100, 100)];
            case CreepingLine:
                components = [wrap(new CreepingLine(), 100, 100)];
            case CompactLiveActionBar:
                autoHeight = true;
                components = [wrap(new LiveActionBar(true), 100, null)];
            case CompactAnalysisActionBar:
                autoHeight = true;
                components = [wrap(new AnalysisActionBar(true), 100, null)];
            case Chat:
                components = [wrap(new Chatbox(), 100, 100)];
            case GameInfoSubscreen:
                autoHeight = true;
                components = [wrap(new GameInfoBox(), 100, null), wrap(new SpectatorList(), 100, null)];
            case BoardAndClocks:
                components = [wrap(new CompactBoardAndClocks(), 100, 100)];
            case SpecialControlSettings:
                autoHeight = true;
                components = []; //TODO: Add corresponding component

        }
    }
}