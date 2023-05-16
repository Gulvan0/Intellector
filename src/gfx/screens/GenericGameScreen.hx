package gfx.screens;

import gfx.game.events.ModelUpdateEvent;
import gfx.game.events.PositionEditorEvent;
import gfx.game.events.VariationViewEvent;
import gfx.game.events.PlyHistoryViewEvent;
import gfx.game.events.ActionBarEvent;
import gfx.game.events.ChatboxEvent;
import gfx.game.events.GameboardEvent;
import gfx.game.interfaces.IGameScreen;
import gfx.game.models.ReadOnlyModel;
import gfx.game.interfaces.IGameComponent;
import haxe.ui.containers.Box;
import gfx.game.common.CompactSubscreen;
import gfx.game.common.Panel;
import gfx.game.common.ComponentPageName;
import gfx.game.common.PanelName;
import net.shared.utils.MathUtils;
import haxe.ui.events.UIEvent;
import gfx.scene.Screen;
import haxe.ui.core.Component;
import gfx.ResponsiveToolbox.ResponsivenessRule;
import gfx.ResponsiveToolbox.ResponsiveProperty;
import net.shared.dataobj.ViewedScreen;
import dict.Phrase;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/game/generic_game_screen.xml"))
abstract class GenericGameScreen extends Screen implements IGameScreen
{
    private var panels:Map<PanelName, Panel> = [];
    private var subscreens:Map<ComponentPageName, CompactSubscreen> = [];
    private var gameComponents:Array<IGameComponent> = [];

    public abstract function getTitle():Null<Phrase>;
    public abstract function getURLPath():Null<String>;
    public abstract function getPage():ViewedScreen;

    private abstract function customOnEnter():Void;
    private abstract function customOnClose():Void;

    private abstract function getModel():ReadOnlyModel;

    public abstract function handleGameboardEvent(event:GameboardEvent):Void;
    public abstract function handleChatboxEvent(event:ChatboxEvent):Void;
    public abstract function handleActionBarEvent(event:ActionBarEvent):Void;
    public abstract function handlePlyHistoryViewEvent(event:PlyHistoryViewEvent):Void;
    public abstract function handleVariationViewEvent(event:VariationViewEvent):Void;
    public abstract function handlePositionEditorEvent(event:PositionEditorEvent):Void;

    private function getResponsiveComponents():Map<Component, Map<ResponsiveProperty, ResponsivenessRule>>
    {
        return [];
    }

    private function onEnter()
    {
        customOnEnter();
    }
    
    private function onClose()
    {
        for (gameComponent in gameComponents)
            gameComponent.destroy();

        customOnClose();
    }

    @:bind(this, UIEvent.RESIZE)
    private function onResize(e)
    {
        var aspectRatio:Float = width / height;

        if (aspectRatio < 1.3)
            layoutStack.selectedId = "compactLayout";
        else 
            layoutStack.selectedId = "largeLayout";


        var boxCount:Int;

        if (aspectRatio < 1.67)
        {
            largeLeftBox.hidden = true;
            boxCount = 1;
        }
        else
        {
            largeLeftBox.hidden = false;
            boxCount = 2;
        }

        var boxWidth:Float = MathUtils.clamp(width * 0.45 / boxCount, 250, 350);
        largeLeftBox.width = boxWidth;
        largeRightBox.width = boxWidth;
    }

    private function getPanelContainer(panelName:PanelName):Box
    {
        return switch panelName 
        {
            case LargeBoardBox: largeBoardBox;
            case LargeExtras: largeExtrasBox;
            case LargeLeft: largeLeftBox;
            case LargeRight: largeRightBox;
            case CompactBoardBox: compactBoardBox;
            case CompactExtras: compactExtrasBox;
            case CompactTop: compactTopBox;
            case CompactBottom: compactBottomBox;
        }
    }

    private function fill(panelMap:Map<PanelName, Array<ComponentPageName>>, subscreenNames:Array<ComponentPageName>)
    {
        for (panelName => panelPages in panelMap.keyValueIterator())
        {
            var panel:Panel = new Panel();
            var childGameComponents:Array<IGameComponent> = panel.updatePages(panelPages);
            getPanelContainer(panelName).addComponent(panel);
            panels.set(panelName, panel);
            gameComponents = gameComponents.concat(childGameComponents);
        }

        for (pageName in subscreenNames)
        {
            var subscreen:CompactSubscreen = new CompactSubscreen();
            var childGameComponents:Array<IGameComponent> = subscreen.updatePage(pageName);
            subscreens.set(pageName, subscreen);
            gameComponents = gameComponents.concat(childGameComponents);
        }
    }

    private function initAllComponents()
    {
        for (gameComponent in gameComponents)
            gameComponent.init(getModel(), this);
    }

    private function emitModelUpdateEvent(event:ModelUpdateEvent)
    {
        for (gameComponent in gameComponents)
            gameComponent.handleModelUpdate(getModel(), event);
    }

    private function setPageDisabled(page:ComponentPageName, pageDisabled:Bool)
    {
        for (panel in panels)
            panel.setPageDisabled(page, pageDisabled);

        var subscreen:Null<CompactSubscreen> = subscreens.get(page);
        if (subscreen != null)
            subscreen.setDisabled(pageDisabled);
    }

    private function setPageHidden(page:ComponentPageName, pageHidden:Bool)
    {
        for (panel in panels)
            panel.setPageHidden(page, pageHidden);

        var subscreen:Null<CompactSubscreen> = subscreens.get(page);
        if (subscreen != null)
            subscreen.setHidden(pageHidden);
    }

    private function displaySubscreen(page:ComponentPageName)
    {
        var subscreen:Null<CompactSubscreen> = subscreens.get(page);
        if (subscreen != null)
            subscreen.displaySubscreen();
    }

    public function new()
    {
        super();
    }
}