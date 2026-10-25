package client.ui.common.account;

import client.auth.Identity;
import client.formatters.IdentityFormatters;
import haxe.ui.components.Button;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.menu.MenuDropdownWidget;
import haxefolio.menu.MenuItemDefinition;

using client.ui.ComponentExtension;

/**
    The menu bar's account widget: the identity's icon, and a menu headed by the identity's name -
    a link to the player's profile, plain text for a guest.
**/
class AccountWidget
{
    public static inline final MENU_SLUG:String = "account";

    /** What goes into the menu bar **/
    public final dropdown:MenuDropdownWidget;

    private final icon:AccountIcon;
    private final header:Button;

    private var identity:Identity = Guest(null);

    public function new(items:Array<MenuItemDefinition>)
    {
        icon = new AccountIcon();
        dropdown = new MenuDropdownWidget(icon, MENU_SLUG, items, StyleVars.ACCOUNT_DROPDOWN_WIDTH);

        header = new Button();
        header.addClass("haxefolio-dropdown-menu-item");
        header.addClass(StyleClass.ACCOUNT_HEADER);
        header.percentWidth = 100;
        header.icon = Assets.menuItemIcon("my_profile");
        header.onClick = _ -> onHeaderClicked();
        dropdown.setHeader(header);

        render(identity);
    }

    public function render(identity:Identity):Void
    {
        this.identity = identity;

        var name:String = IdentityFormatters.formatRaw(identity);
        icon.setIdentity(identity);
        header.text = name;
        header.setClass(StyleClass.ACCOUNT_HEADER_GUEST, identity.isGuest());
        dropdown.setAccessibleName(LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.account_widget.accessible_name"), LocaleUtils.resolveText(name)));
    }

    private function onHeaderClicked():Void
    {
        var login:Null<String> = identity.getLogin();
        if (login == null)
            return;

        dropdown.close();
        HaxeFolioApp.navigateTo('player/$login');
    }
}
