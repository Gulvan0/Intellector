package gfx.menu;

import net.Requests;
import gfx.popups.Settings;
import gfx.popups.LogIn;
import haxe.ui.events.MouseEvent;
import gfx.ResponsiveToolbox.ResponsivenessRule;
import gfx.ResponsiveToolbox.ResponsiveProperty;
import net.shared.ServerEvent;
import net.shared.dataobj.ChallengeData;
import net.INetObserver;
import GlobalBroadcaster.IGlobalEventObserver;
import GlobalBroadcaster.GlobalEvent;
import dict.Dictionary;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar as HaxeUIMenuBar;
import haxe.ui.containers.menus.MenuItem as HaxeUIMenuItem;
import haxe.ui.core.Screen as HaxeUIScreen;

using utils.StringUtils;

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/menu/menu_bar.xml'))
class MenuBar extends HaxeUIMenuBar implements IGlobalEventObserver
{
    private var sidemenu:SideMenu;

    private var sectionMenus:Map<MenuSection, Menu> = [];
    private var menuItems:Map<MenuItemName, HaxeUIMenuItem> = [];

    public function refreshLanguage()
    {
        for (section => menu in sectionMenus.keyValueIterator())
            menu.text = Dictionary.getPhrase(MENU_SECTION_TITLE(section));

        for (itemName => menuItem in menuItems.keyValueIterator())
            menuItem.text = Dictionary.getPhrase(MENU_ITEM_NAME(itemName));

        sidemenu.refreshLanguage();
    }

    public function resize()
    {
        var siteNameRules:Map<ResponsiveProperty, ResponsivenessRule> = [StyleProp(PaddingLeft) => VH(1), StyleProp(PaddingRight) => VH(1), StyleProp(FontSize) => VH(3)];
        var mobileMenuButtonRules:Map<ResponsiveProperty, ResponsivenessRule> = [Width => VH(2.6), Height => VH(2.2)];

        var compact:Bool = HaxeUIScreen.instance.actualWidth < 0.9 * HaxeUIScreen.instance.actualHeight;

        ResponsiveToolbox.resizeComponent(siteName, siteNameRules);
        ResponsiveToolbox.resizeComponent(mobileMenuButton, mobileMenuButtonRules);
        mobileMenuButton.hidden = !compact;

        for (btn in findComponents('menubar-button'))
        {
            if (btn.text != accountMenu.text && btn.text != challengesMenu.text)
                btn.hidden = compact;
            
            if (btn.text != challengesMenu.text)
                ResponsiveToolbox.resizeComponent(btn, [StyleProp(FontSize) => VH(2), Height => VH(4)]);
            else
                ResponsiveToolbox.resizeComponent(btn, [Height => VH(4)]);
        }
        
        ResponsiveToolbox.resizeComponent(challengesMenu.flagIcon, [Width => VH(3), Height => VH(3)]);

        sidemenu.resize();
    }

    private function setIngameStatus(ingame:Bool)
    {
        mobileMenuButton.disabled = ingame;
        siteName.disabled = ingame;

        for (menu in sectionMenus)
            menu.disabled = ingame;
        
        challengesMenu.disabled = ingame;
        logInBtn.disabled = ingame;
        myProfileBtn.disabled = ingame;
        logOutBtn.disabled = ingame;
    }

    private function refreshAccountElements()
    {
        var logged:Bool = LoginManager.isLogged();
        accountMenu.text = logged? LoginManager.getLogin().shorten(8) : Dictionary.getPhrase(MENUBAR_ACCOUNT_MENU_GUEST_DISPLAY_NAME);
        logInBtn.hidden = logged;
        myProfileBtn.hidden = !logged;
        logOutBtn.hidden = !logged;
    }

    @:bind(logInBtn, MouseEvent.CLICK)
    private function onLogInPressed(e)
    {
        Dialogs.getQueue().add(new LogIn());
    }

    @:bind(myProfileBtn, MouseEvent.CLICK)
    private function onMyProfilePressed(e)
    {
        Requests.getPlayerProfile(LoginManager.getLogin());
    }

    @:bind(settingsBtn, MouseEvent.CLICK)
    private function onSettingsPressed(e)
    {
        Dialogs.getQueue().add(new Settings());
    }

    @:bind(logOutBtn, MouseEvent.CLICK)
    private function onLogOutPressed(e)
    {
        LoginManager.removeCredentials();
        Networker.emitEvent(LogOut);
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case LoggedIn, LoggedOut:
                refreshAccountElements();
            case InGame:
                setIngameStatus(true);
            case NotInGame:
                setIngameStatus(false);
            case Disconnected:
                disabled = true;
            case Connected:
                disabled = false;
            default:
        }
    }

    public function new(sections:Array<MenuSection>, items:Map<MenuSection, Array<MenuItem>>, clickHandler:MenuItemName->Void, onSiteNamePressed:Void->Void)
    {
        super();
        sidemenu = new SideMenu(sections, items, clickHandler, onSiteNamePressed);
        disabled = !Networker.isConnectedToServer();

        for (section in sections)
        {
            var sectionMenu:Menu = new Menu();
            sectionMenu.text = Dictionary.getPhrase(MENU_SECTION_TITLE(section));

            sectionMenus.set(section, sectionMenu);
            addComponent(sectionMenu);

            for (item in items.get(section))
            {
                var menuItem:HaxeUIMenuItem = new HaxeUIMenuItem();
                menuItem.text = Dictionary.getPhrase(item.displayName);
                menuItem.icon = item.itemIconPath;
                menuItem.onClick = e -> {clickHandler(item.itemName);};

                menuItems.set(item.itemName, menuItem);
                sectionMenu.addComponent(menuItem);
            }
        }

        mobileMenuButton.onClick = e -> {sidemenu.show();};
        siteName.onClick = e -> {onSiteNamePressed();};

        refreshAccountElements();

        GlobalBroadcaster.addObserver(this);
    }
}