package gfx.screens;

import net.shared.ServerEvent;
import net.EventProcessingQueue.INetObserver;
import net.shared.dataobj.GameInfo;
import net.shared.dataobj.ChallengeData;
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
        Networker.addObserver(this);
    }

    public function onClose()
    {
        Networker.removeObserver(this);
        SceneManager.removeResizeHandler(onResize);
    }

    public function handleNetEvent(event:ServerEvent) 
    {
        switch event 
        {
            case MainMenuData(openChallenges, currentGames, recentGames):
                openChallengesTable.appendChallenges(openChallenges);
                currentGamesTable.appendGames(currentGames);
                pastGamesList.appendGames(recentGames);
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

    private override function onReady()
    {
        super.onReady();
        onResize();
        SceneManager.addResizeHandler(onResize);
    }

    private function onResize() 
    {
        var compact:Bool = HaxeUIScreen.instance.actualWidth / HaxeUIScreen.instance.actualHeight < 1.2;

        var newStyle:Style = changelogLabel.customStyle.clone();
        newStyle.fontSize = Math.min(1.8 * HaxeUIScreen.instance.actualWidth / Changelog.getFirstLength(), 26);
        changelogLabel.customStyle = newStyle;

        contentHBox.percentWidth = compact? 100 : 90;
        tablesBox.percentWidth = compact? 100 : 50;
        tablesBox.percentHeight = compact? 66.66 : 100;
        pastGamesList.percentWidth = compact? 100 : 50;
        pastGamesList.percentHeight = compact? 33.33 : 100;

        var tableHeaderHeightRule:ResponsivenessRule = Min([Exact(30), VMIN(5)]);
        var tableHeaderBoxHeightRule:ResponsivenessRule = Min([Exact(40), VMIN(6.66)]);
        var tableHeaderReloadBtnHeightRule:ResponsivenessRule = Min([Exact(20), VMIN(3.33)]);

        ResponsiveToolbox.resizeComponent(contentHBox, [StyleProp(HorizontalSpacing) => VW(8)]);
        
        ResponsiveToolbox.resizeComponent(openChallengesTable.tableTitleBox, [Height => tableHeaderBoxHeightRule]);
        ResponsiveToolbox.resizeComponent(openChallengesTable.title, [StyleProp(FontSize) => tableHeaderHeightRule]);
        ResponsiveToolbox.resizeComponent(openChallengesTable.reloadBtn, [StyleProp(FontSize) => tableHeaderReloadBtnHeightRule, IconWidth => tableHeaderReloadBtnHeightRule, IconHeight => tableHeaderReloadBtnHeightRule]);

        ResponsiveToolbox.resizeComponent(currentGamesTable.tableTitleBox, [Height => tableHeaderBoxHeightRule]);
        ResponsiveToolbox.resizeComponent(currentGamesTable.title, [StyleProp(FontSize) => tableHeaderHeightRule]);
        ResponsiveToolbox.resizeComponent(currentGamesTable.reloadBtn, [StyleProp(FontSize) => tableHeaderReloadBtnHeightRule, IconWidth => tableHeaderReloadBtnHeightRule, IconHeight => tableHeaderReloadBtnHeightRule]);

        ResponsiveToolbox.resizeComponent(pastGamesList.tableTitleBox, [Height => tableHeaderBoxHeightRule]);
        ResponsiveToolbox.resizeComponent(pastGamesList.title, [StyleProp(FontSize) => tableHeaderHeightRule]);
    }

    public function new()
    {
        super();
        
        customEnterHandler = onEnter;
        customCloseHandler = onClose;
    }
}