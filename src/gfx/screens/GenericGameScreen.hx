package gfx.screens;

import gfx.utils.SpecialControlSettings as SpControlSettings;
import gfx.game.interfaces.IGameScreen;
import net.shared.ServerEvent;
import gfx.game.interfaces.IBehaviour;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.events.PositionEditorEvent;
import gfx.game.events.VariationViewEvent;
import gfx.game.events.PlyHistoryViewEvent;
import gfx.game.events.ActionBarEvent;
import gfx.game.events.ChatboxEvent;
import gfx.game.events.GameboardEvent;
import gfx.game.interfaces.IBehaviour;
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

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/screens/generic_game_screen.xml"))
abstract class GenericGameScreen extends Screen implements IGameScreen
{
    private var panels:Map<PanelName, Panel> = [];
    private var subscreens:Map<ComponentPageName, CompactSubscreen> = [];
    private var gameComponents:Array<IGameComponent> = [];

    private var behaviour(default, set):IBehaviour;
    
    private var compactSpecialControlSettings:SpControlSettings = SpControlSettings.normal();

    public abstract function getTitle():Null<Phrase>;
    public abstract function getURLPath():Null<String>;
    public abstract function getPage():ViewedScreen;

    private abstract function customOnEnter():Void;
    private abstract function customOnClose():Void;

    private abstract function getModel():ReadOnlyModel;

    private abstract function processModelUpdateAtTopLevel(update:ModelUpdateEvent):Void;

    private function getResponsiveComponents():Map<Component, Map<ResponsiveProperty, ResponsivenessRule>>
    {
        return [];
    }

    public function getBehaviour():IBehaviour
    {
        return behaviour;
    }

    public function getSpecialControlSettings():SpControlSettings
    {
        if (layoutStack.selectedId == "compactLayout")
            return compactSpecialControlSettings;
        else
            return SpControlSettings.normal();
    }

    private function onEnter()
    {
        customOnEnter();
    }
    
    private function onClose()
    {
        if (behaviour != null)
            Networker.removeObserver(behaviour);

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

    private function processModelUpdate(updateToProcess:ModelUpdateEvent)
    {
        var model:ReadOnlyModel = getModel();

        for (gameComponent in gameComponents)
            gameComponent.handleModelUpdate(model, updateToProcess);

        processModelUpdateAtTopLevel(updateToProcess);
    }

    private function set_behaviour(behaviour:IBehaviour):IBehaviour
    {
        if (this.behaviour != null)
        {
            Networker.removeObserver(this.behaviour);
            GlobalBroadcaster.removeObserver(this.behaviour);
        }

        this.behaviour = behaviour;

        Networker.addObserver(this.behaviour);
        GlobalBroadcaster.addObserver(this.behaviour);
        
        this.behaviour.onEntered(processModelUpdate, this);

        return this.behaviour;
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

    private function init(initialBehaviour:IBehaviour, panelMap:Map<PanelName, Array<ComponentPageName>>, subscreenNames:Array<ComponentPageName>)
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

        var model:ReadOnlyModel = getModel();

        for (gameComponent in gameComponents)
            gameComponent.init(model, this);

        this.behaviour = initialBehaviour;
    }

    public function setPageDisabled(page:ComponentPageName, pageDisabled:Bool)
    {
        for (panel in panels)
            panel.setPageDisabled(page, pageDisabled);

        var subscreen:Null<CompactSubscreen> = subscreens.get(page);
        if (subscreen != null)
            subscreen.setDisabled(pageDisabled);
    }

    public function setPageHidden(page:ComponentPageName, pageHidden:Bool)
    {
        for (panel in panels)
            panel.setPageHidden(page, pageHidden);

        var subscreen:Null<CompactSubscreen> = subscreens.get(page);
        if (subscreen != null)
            subscreen.setHidden(pageHidden);
    }

    public function displaySubscreen(page:ComponentPageName)
    {
        var subscreen:Null<CompactSubscreen> = subscreens.get(page);
        if (subscreen != null)
            subscreen.displaySubscreen();
    }

    public function changeBehaviour(newBehaviour:IBehaviour)
    {
        this.behaviour = newBehaviour;
    }

    public function new()
    {
        super();
    }
}