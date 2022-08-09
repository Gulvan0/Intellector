package gfx;

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
class Scene extends VBox
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
                ResponsiveToolbox.resizeComponent(btn, [StyleProp(FontSize) => VH(2)]);
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
        toScreen(MainMenu);
    }

    private function onCreateChallengePressed(e)
    {
        Dialogs.specifyChallengeParams((_, _, _) -> {createChallenge();});
    }

    private function createChallenge() 
    {
        //TODO: Implement
    }

    private function onOpenChallengesPressed(e)
    {
        //TODO: toScreen
    }

    private function onCurrentGamesPressed(e)
    {
        //TODO: toScreen
    }

    private function onWatchPlayerPressed(e)
    {
        Dialogs.prompt("Введите ник игрока", All, startSpectating);
    }

    private function startSpectating(requestedLogin:String)
    {
        Requests.watchPlayer(requestedLogin, onSpectationData.bind(requestedLogin), Dialogs.alertCallback("В настоящий момент игрок не участвует в партии", "Ошибка"), Dialogs.alertCallback("Игрок не в сети", "Ошибка"), Dialogs.alertCallback("Игрок не найден", "Ошибка"));
    }

    private function onSpectationData(watchedPlayer:String, match_id:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String)
    {
        var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
        toScreen(LiveGame(match_id, Ongoing(parsedData, whiteSeconds, blackSeconds, timestamp, watchedPlayer)));
    }

    private function onAnalysisBoardPressed(e)
    {
        toScreen(Analysis(null, null, null));
    }

    private function onPlayerProfilePressed(e)
    {
        Dialogs.prompt("Введите ник игрока", All, navigateToProfile);
    }

    private function navigateToProfile(requestedLogin:String)
    {
        //TODO: Implement properly (pass info)
        Requests.getPlayerProfile(requestedLogin, toScreen.bind(PlayerProfile(requestedLogin)), Dialogs.alertCallback("Игрок не найден", "Ошибка"));
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
        //TODO: Implement + design global event handling
    }

    public function new()
    {
        super();
        var logged:Bool = LoginManager.login != null;
        accountMenu.text = logged? LoginManager.login : "Гость";
        logInBtn.hidden = logged;
        myProfileBtn.hidden = !logged;
        logOutBtn.hidden = !logged;

        //TODO: Challenges
        
        sidemenu = new SideMenu();
        sidemenu.siteName.onClick = siteName.onClick = onSiteNamePressed;
        sidemenu.createChallengeBtn.onClick = createChallengeBtn.onClick = onCreateChallengePressed;
        sidemenu.openChallengesBtn.onClick = openChallengesBtn.onClick = onOpenChallengesPressed;
        sidemenu.currentGamesBtn.onClick = currentGamesBtn.onClick = onCurrentGamesPressed;
        sidemenu.watchPlayerBtn.onClick = watchPlayerBtn.onClick = onWatchPlayerPressed;
        sidemenu.analysisBoardBtn.onClick = analysisBoardBtn.onClick = onAnalysisBoardPressed;
        sidemenu.playerProfileBtn.onClick = playerProfileBtn.onClick = onPlayerProfilePressed;

        logInBtn.onClick = onLogInPressed;
        myProfileBtn.onClick = onMyProfilePressed;
        settingsBtn.onClick = onSettingsPressed;
        logOutBtn.onClick = onLogOutPressed;
    }

}