package gfx.screens;

import net.shared.ServerEvent;
import net.EventProcessingQueue.INetObserver;
import net.shared.GameInfo;
import net.shared.ChallengeData;
import net.Requests;
import haxe.ui.styles.Style;
import gfx.ResponsiveToolbox;
import gfx.Dialogs;
import haxe.ui.events.MouseEvent;
import dict.Dictionary;
import utils.Changelog;
import haxe.ui.core.Screen as HaxeUIScreen;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/main_menu/main_menu.xml"))
class MainMenu extends Screen implements INetObserver
{
    public function onEnter()
    {
        Requests.getMainMenuData(onMainMenuData);
        Networker.addObserver(this);
    }

    public function onClose()
    {
        Networker.removeObserver(this);
        Networker.emitEvent(MainMenuLeft);
    }

    public function handleNetEvent(event:ServerEvent) 
    {
        switch event 
        {
            case MainMenuNewOpenChallenge(data):
                openChallengesTable.appendChallenges([data]);
            case MainMenuNewGame(data):
                currentGamesTable.appendGames([data]);
            case MainMenuGameEnded(data):
                currentGamesTable.removeGame(data.id);
                pastGamesList.insertAtBeginning(data);
            case MainMenuOpenChallengeRemoved(id):
                openChallengesTable.removeChallenge(id);
            default:
        }
    }

    private function onMainMenuData(openChallenges:Array<ChallengeData>, currentGames:Array<GameInfo>, recentGames:Array<GameInfo>)
    {
        openChallengesTable.appendChallenges(openChallenges);
        currentGamesTable.appendGames(currentGames);
        pastGamesList.appendGames(recentGames);
    }

    @:bind(createGameBtn, MouseEvent.CLICK)
    private function onCreateGamePressed(?e)
    {
        if (!LoginManager.isLogged())
            Dialogs.login(displayChallengeParamsDialog);
        else
            displayChallengeParamsDialog();
    }

    private function displayChallengeParamsDialog()
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
        var compact:Bool = HaxeUIScreen.instance.actualWidth / HaxeUIScreen.instance.actualHeight < 1.2;
        var wasCompact:Bool = tablesBox.percentWidth == 100;

        var newStyle:Style = changelogLabel.customStyle.clone();
        newStyle.fontSize = Math.min(1.8 * HaxeUIScreen.instance.actualWidth / Changelog.getFirstLength(), 26);
        changelogLabel.customStyle = newStyle;

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
    
        customEnterHandler = onEnter;
        customCloseHandler = onClose;
    }
}