package gfx;

import dict.Dictionary;
import GlobalBroadcaster.IGlobalEventObserver;
import GlobalBroadcaster.GlobalEvent;
import net.EventProcessingQueue.INetObserver;
import net.ServerEvent;
import utils.StringUtils;
import serialization.GameLogParser;
import net.Requests;
import gfx.components.Dialogs;
import gfx.ResponsiveToolbox.ResponsivenessRule;
import gfx.ResponsiveToolbox.ResponsiveProperty;
import haxe.ui.components.Button;
import haxe.ui.core.Screen as HaxeUIScreen;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.VBox;
import net.LoginManager;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/basic/scene_template.xml'))
class Scene extends VBox implements INetObserver implements IGlobalEventObserver
{
    private var currentScreen:Null<Screen> = null;
    private var sidemenu:SideMenu;

    public function resize()
    {
        var siteNameRules:Map<ResponsiveProperty, ResponsivenessRule> = [StyleProp(PaddingLeft) => VH(1), StyleProp(PaddingRight) => VH(1), StyleProp(FontSize) => VH(3)];
        var mobileMenuButtonRules:Map<ResponsiveProperty, ResponsivenessRule> = [Width => VH(2.6), Height => VH(2.2)];
        var mobileMenuHeaderRules:Map<ResponsiveProperty, ResponsivenessRule> = [StyleProp(FontSize) => VH(1.75)];
        var mobileMenuItemRules:Map<ResponsiveProperty, ResponsivenessRule> = [StyleProp(FontSize) => VH(1.5)];

        var compact:Bool = HaxeUIScreen.instance.width < HaxeUIScreen.instance.height * 0.7;

        ResponsiveToolbox.resizeComponent(sidemenu.siteName, siteNameRules);
        ResponsiveToolbox.resizeComponent(sidemenu.mobileMenuButton, mobileMenuButtonRules);
        ResponsiveToolbox.resizeComponent(sidemenu.mainSpacer, [Height => VH(2)]);
        for (header in sidemenu.findComponents('mobileMenuHeader'))
            ResponsiveToolbox.resizeComponent(header, mobileMenuHeaderRules);
        for (item in sidemenu.findComponents('mobileMenuItem'))
            ResponsiveToolbox.resizeComponent(item, mobileMenuItemRules);
        for (spacer in sidemenu.findComponents('sectionSpacer'))
            ResponsiveToolbox.resizeComponent(spacer, [Height => VH(1)]);

        ResponsiveToolbox.resizeComponent(siteName, siteNameRules);
        ResponsiveToolbox.resizeComponent(mobileMenuButton, mobileMenuButtonRules);
        mobileMenuButton.hidden = !compact;

        for (btn in findComponents('menubar-button'))
        {
            if (btn.text != accountMenu.text && btn.text != challengesButton.text)
                btn.hidden = compact;
            
            if (btn.text != challengesButton.text)
                ResponsiveToolbox.resizeComponent(btn, [StyleProp(FontSize) => VH(2), Height => VH(4)]);
            else
                ResponsiveToolbox.resizeComponent(btn, [Height => VH(4)]);
        }
    }

    private function setIngameStatus(ingame:Bool)
    {
        mobileMenuButton.disabled = ingame;
        siteName.disabled = ingame;
        playMenu.disabled = ingame;
        watchMenu.disabled = ingame;
        learnMenu.disabled = ingame;
        socialMenu.disabled = ingame;
        challengesButton.disabled = ingame;
        logInBtn.disabled = ingame;
        myProfileBtn.disabled = ingame;
        logOutBtn.disabled = ingame;
    }

    public function handleNetEvent(event:ServerEvent)
    {
        switch event
        {
            case GameStarted(_, _):
                setIngameStatus(true);
            case GameEnded(_, _):
                setIngameStatus(false);
            default:
        }
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case LoggedIn, LoggedOut:
                refreshAccountElements();
            default:
        }
    }

    public function toScreen(type:Null<ScreenType>)
    {
        if (currentScreen != null)
        {
            currentScreen.onClosed();
            content.removeComponent(currentScreen);
        }

        if (type == null)
            currentScreen = null;
        else
        {
            currentScreen = Screen.build(type);
            menubar.hidden = currentScreen.menuHidden;
            content.addComponent(currentScreen);
            currentScreen.onEntered();
        }
    }

    private function onSiteNamePressed(e) 
    {
        ScreenManager.toScreen(MainMenu);
    }

    private function onCreateChallengePressed(e)
    {
        if (LoginManager.login == null)
            Dialogs.login(displayChallengeParamsDialog);
        else
            displayChallengeParamsDialog();
    }

    private function displayChallengeParamsDialog()
    {
        Dialogs.specifyChallengeParams();
    }

    private function onOpenChallengesPressed(e)
    {
        ScreenManager.toScreen(MainMenu);
    }

    private function onCurrentGamesPressed(e)
    {
        ScreenManager.toScreen(MainMenu);
    }

    private function onWatchPlayerPressed(e)
    {
        Dialogs.prompt(Dictionary.getPhrase(INPUT_PLAYER_LOGIN), All, startSpectating);
    }

    private function startSpectating(requestedLogin:String)
    {
        Requests.watchPlayer(requestedLogin);
    }

    private function onSpectationData(watchedPlayer:String, match_id:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String)
    {
        var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
        ScreenManager.toScreen(LiveGame(match_id, Ongoing(parsedData, whiteSeconds, blackSeconds, timestamp, watchedPlayer)));
    }

    private function onAnalysisBoardPressed(e)
    {
        ScreenManager.toScreen(Analysis(null, null, null, null));
    }

    private function onPlayerProfilePressed(e)
    {
        Dialogs.prompt(Dictionary.getPhrase(INPUT_PLAYER_LOGIN), All, navigateToProfile);
    }

    private function navigateToProfile(requestedLogin:String)
    {
        Requests.getPlayerProfile(requestedLogin);
    }

    private function onLogInPressed(e)
    {
        Dialogs.login();
    }

    private function onMyProfilePressed(e)
    {
        navigateToProfile(LoginManager.login);
    }

    private function onSettingsPressed(e)
    {
        Dialogs.settings();
    }

    private function onLogOutPressed(e)
    {
        LoginManager.logout();
    }

    private function refreshAccountElements()
    {
        var logged:Bool = LoginManager.login != null;
        accountMenu.text = logged? StringUtils.shorten(LoginManager.login, 8) : Dictionary.getPhrase(MENUBAR_ACCOUNT_MENU_GUEST_DISPLAY_NAME);
        logInBtn.hidden = logged;
        myProfileBtn.hidden = !logged;
        logOutBtn.hidden = !logged;
        //TODO: Clear or populate challenge list
    }

    public function new()
    {
        super();

        refreshAccountElements();

        //TODO: Challenges
        
        sidemenu = new SideMenu();
        siteName.onClick = onSiteNamePressed;
        createChallengeBtn.onClick = onCreateChallengePressed;
        openChallengesBtn.onClick = onOpenChallengesPressed;
        currentGamesBtn.onClick = onCurrentGamesPressed;
        watchPlayerBtn.onClick = onWatchPlayerPressed;
        analysisBoardBtn.onClick = onAnalysisBoardPressed;
        playerProfileBtn.onClick = onPlayerProfilePressed;

        sidemenu.siteName.onClick = e -> {sidemenu.hide(); onSiteNamePressed(e);};
        sidemenu.createChallengeBtn.onClick = e -> {sidemenu.hide(); onCreateChallengePressed(e);};
        sidemenu.openChallengesBtn.onClick = e -> {sidemenu.hide(); onOpenChallengesPressed(e);};
        sidemenu.currentGamesBtn.onClick = e -> {sidemenu.hide(); onCurrentGamesPressed(e);};
        sidemenu.watchPlayerBtn.onClick = e -> {sidemenu.hide(); onWatchPlayerPressed(e);};
        sidemenu.analysisBoardBtn.onClick = e -> {sidemenu.hide(); onAnalysisBoardPressed(e);};
        sidemenu.playerProfileBtn.onClick = e -> {sidemenu.hide(); onPlayerProfilePressed(e);};

        logInBtn.onClick = onLogInPressed;
        myProfileBtn.onClick = onMyProfilePressed;
        settingsBtn.onClick = onSettingsPressed;
        logOutBtn.onClick = onLogOutPressed;
    }

}