package gfx.game.common;

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

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/game/panel.xml"))
class Panel extends Stack
{
    private var pages:Array<ComponentPageName> = [];
    private var pageComponents:Map<ComponentPageName, Box> = [];
    private var currentMode:PanelDisplayMode;

    private function modeByPagesCount(cnt:Int):PanelDisplayMode
    {
        if (cnt == 0)
            return Hidden;
        else if (cnt == 1)
            return SinglePage;
        else
            return TabView;
    }

    public function setPages(pages:Array<ComponentPageName>)
    {
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

                selectedId = "singlepage";
            case TabView:
                for (pageName in pages)
                {
                    var builder:ComponentPageBuilder = new ComponentPageBuilder(pageName);
                    var page:Box = builder.buildPage();
                    pageComponents.set(pageName, page);
                    tabview.addComponent(page);
                }

                selectedId = "tabview";
        }
    }

    private function isPageActive(page:ComponentPageName):Bool
    {
        var pageComponent = pageComponents.get(page);

        if (pageComponent == null)
            return false;
        else
            return !pageComponent.hidden;
    }

    public function setPageHidden(page:ComponentPageName, hidden:Bool)
    {
        var pageComponent = pageComponents.get(page);

        if (pageComponent == null)
            return;

        pageComponent.hidden = true;

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