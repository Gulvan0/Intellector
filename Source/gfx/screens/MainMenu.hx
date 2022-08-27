package gfx.screens;

import gfx.ResponsiveToolbox;
import gfx.components.Dialogs;
import haxe.ui.events.MouseEvent;
import dict.Dictionary;
import utils.Changelog;
import haxe.ui.core.Screen as HaxeUIScreen;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/main_menu/main_menu.xml"))
class MainMenu extends Screen
{
    @:bind(createGameBtn, MouseEvent.CLICK)
    private function onCreateGamePressed(?e)
    {
        Dialogs.specifyChallengeParams();
    }

    @:bind(changelogLabel, MouseEvent.CLICK)
    private function onChangelogRequested(?e)
    {
        Dialogs.changelog();
    }

    private override function validateComponentLayout():Bool 
    {
        var compact:Bool = HaxeUIScreen.instance.width / HaxeUIScreen.instance.height < 1.2;
        var wasCompact:Bool = tablesBox.percentWidth == 100;

        contentHBox.percentWidth = compact? 100 : 90;
        tablesBox.percentWidth = compact? 100 : 50;
        tablesBox.percentHeight = compact? 66.66 : 100;
        pastGamesList.percentWidth = compact? 100 : 50;
        pastGamesList.percentHeight = compact? 33.33 : 100;

        var parentChanged:Bool = super.validateComponentLayout();

        return parentChanged || wasCompact != compact;
    }

    public function new()
    {
        super();
        var tableHeaderHeightRule:ResponsivenessRule = Min([Exact(30), VW(6)]);
        var tableHeaderBoxHeightRule:ResponsivenessRule = Min([Exact(40), VW(8)]);
        var tableHeaderReloadBtnHeightRule:ResponsivenessRule = Min([Exact(20), VW(4)]);
        var tableLegendFontSizeRule:ResponsivenessRule = Min([Exact(12), VW(2.5)]);
        var tableLegendPaddingRule:ResponsivenessRule = Min([Exact(8), VW(1)]);
        
        responsiveComponents = [
            contentHBox => [StyleProp(HorizontalSpacing) => VW(10)],
            openChallengesTable.title => [StyleProp(FontSize) => tableHeaderHeightRule],
            currentGamesTable.title => [StyleProp(FontSize) => tableHeaderHeightRule],
            pastGamesList.title => [StyleProp(FontSize) => tableHeaderHeightRule],
            openChallengesTable.reloadBtn => [StyleProp(FontSize) => tableHeaderReloadBtnHeightRule, IconWidth => tableHeaderReloadBtnHeightRule, IconHeight => tableHeaderReloadBtnHeightRule],
            currentGamesTable.reloadBtn => [StyleProp(FontSize) => tableHeaderReloadBtnHeightRule, IconWidth => tableHeaderReloadBtnHeightRule, IconHeight => tableHeaderReloadBtnHeightRule],
            openChallengesTable.tableTitleBox => [Height => tableHeaderBoxHeightRule],
            currentGamesTable.tableTitleBox => [Height => tableHeaderBoxHeightRule],
            pastGamesList.tableTitleBox => [Height => tableHeaderBoxHeightRule],
        ];
        for (column in openChallengesTable.tableHeader.childComponents)
            responsiveComponents.set(column, [StyleProp(FontSize) => tableLegendFontSizeRule, StyleProp(PaddingTop) => tableLegendPaddingRule, StyleProp(PaddingBottom) => tableLegendPaddingRule, StyleProp(PaddingLeft) => tableLegendPaddingRule, StyleProp(PaddingRight) => tableLegendPaddingRule]);
        for (column in currentGamesTable.tableHeader.childComponents)
            responsiveComponents.set(column, [StyleProp(FontSize) => tableLegendFontSizeRule, StyleProp(PaddingTop) => tableLegendPaddingRule, StyleProp(PaddingBottom) => tableLegendPaddingRule, StyleProp(PaddingLeft) => tableLegendPaddingRule, StyleProp(PaddingRight) => tableLegendPaddingRule]);
    }
}