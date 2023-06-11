package gfx.game.common;

import gfx.game.interfaces.IGameComponent;
import haxe.ui.containers.Box;
import haxe.ui.core.Component;
import haxe.ui.containers.Stack;
import haxe.ui.containers.VBox;

using Lambda;

private enum PanelDisplayMode
{
    TabView;
    SinglePage;
    Hidden;
}

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/game/common/panel.xml"))
class Panel extends Stack
{
    private var pages:Array<ComponentPageName> = [];
    private var pageComponents:Map<ComponentPageName, Box> = [];
    private var currentMode:PanelDisplayMode;

    private override function set_hidden(value:Bool):Bool 
    {
        if (parentComponent != null)
            parentComponent.hidden = value;
        return super.set_hidden(value);
    }

    private function modeByPagesCount(cnt:Int):PanelDisplayMode
    {
        if (cnt == 0)
            return Hidden;
        else if (cnt == 1)
            return SinglePage;
        else
            return TabView;
    }

    /**
        @return All game components contained in this panel
    **/
    public function updatePages(pages:Array<ComponentPageName>):Array<IGameComponent>
    {
        var allGameComponents:Array<IGameComponent> = [];

        tabview.removeAllPages();
        singlepage.removeAllComponents();

        this.pages = pages;
        currentMode = modeByPagesCount(pages.length);

        switch (currentMode)
        {
            case Hidden:
                hidden = true;
            case SinglePage:
                var builder:ComponentPageBuilder = new ComponentPageBuilder(pages[0]);
                var page:Box = builder.buildPage();
                pageComponents.set(pages[0], page);
                singlepage.addComponent(page);
                allGameComponents = allGameComponents.concat(builder.allComponents());

                selectedId = "singlepage";
                hidden = false;
            case TabView:
                for (pageName in pages)
                {
                    var builder:ComponentPageBuilder = new ComponentPageBuilder(pageName);
                    var page:Box = builder.buildPage();
                    pageComponents.set(pageName, page);
                    tabview.addComponent(page);
                    allGameComponents = allGameComponents.concat(builder.allComponents());
                }

                selectedId = "tabview";
                hidden = false;
        }

        return allGameComponents;
    }

    private function isPageActive(page:ComponentPageName):Bool
    {
        var pageComponent = pageComponents.get(page);

        if (pageComponent == null)
            return false;
        else
            return !pageComponent.hidden;
    }

    public function setPageDisabled(page:ComponentPageName, pageDisabled:Bool)
    {
        var pageComponent = pageComponents.get(page);

        if (pageComponent == null)
            return;

        pageComponent.disabled = pageDisabled;
    }

    public function setPageHidden(page:ComponentPageName, pageHidden:Bool)
    {
        var pageComponent = pageComponents.get(page);

        if (pageComponent == null)
            return;

        pageComponent.hidden = pageHidden;

        var newMode:PanelDisplayMode = modeByPagesCount(pages.count(isPageActive));

        if (newMode == currentMode)
            return;

        switch currentMode 
        {
            case TabView:
                tabview.removeAllPages();
            case SinglePage:
                singlepage.removeAllComponents();
            case Hidden:
                hidden = false;
        }

        switch newMode 
        {
            case TabView:
                for (pageName in pages)
                {
                    var page:Box = pageComponents.get(pageName);
                    if (!page.hidden)
                        tabview.addComponent(page);
                }
            case SinglePage:
                for (pageName in pages)
                {
                    var page:Box = pageComponents.get(pageName);
                    if (!page.hidden)
                    {
                        singlepage.addComponent(page);
                        break;
                    }
                }
            case Hidden:
                hidden = true;
        }

        currentMode = newMode;
    }

    public function new()
    {
        super();
    }
}