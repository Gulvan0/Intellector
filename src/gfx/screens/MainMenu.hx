package gfx.screens;

import gfx.scene.SceneManager;
import gfx.scene.Screen;
import haxe.ui.core.Component;
import dict.Phrase;
import net.shared.dataobj.ViewedScreen;
import tests.Interceptor;
import gfx.popups.LogIn;
import gfx.popups.ChallengeParamsDialog;
import gfx.popups.ChangelogDialog;
import net.shared.ServerEvent;
import net.INetObserver;
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
    private function onEnter()
    {
        Networker.addObserver(this);
    }

    private function onClose()
    {
        Networker.removeObserver(this);
        SceneManager.removeResizeHandler(onResize);
    }

    public function getTitle():Null<Phrase>
    {
        return MAIN_MENU_SCREEN_TITLE;
    }

    public function getURLPath():Null<String>
    {
        return "home";
    }

    public function getPage():ViewedScreen
    {
        return MainMenu;
    }

    private function getResponsiveComponents():Map<Component, Map<ResponsiveProperty, ResponsivenessRule>>
    {
        return [];
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
            Dialogs.getQueue().add(new LogIn(displayChallengeParamsDialog));
        else
            displayChallengeParamsDialog();
    }

    private function displayChallengeParamsDialog()
    {
        Dialogs.getQueue().add(new ChallengeParamsDialog());
    }

    @:bind(changelogLabel, MouseEvent.CLICK)
    private function onChangelogRequested(?e)
    {
        Dialogs.getQueue().add(new ChangelogDialog());
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
        pastGamesList.percentWidth = compact? 100 : 50;

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
    }
}