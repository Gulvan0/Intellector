package client.ui.common.overlays.login;

import haxe.ui.Toolkit;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.overlay.OverlayContent;
import haxefolio.structure.ActionBar;
import haxefolio.structure.ActionButton;
import haxefolio.structure.Region;
import haxefolio.structure.TabLock;
import haxefolio.structure.TabPage;

/*
    Log In and Register as tabs, one `LoginForm` each. The overlay owns what they share: the primary
    button, relabelled per tab, and the tab lock held during a request. Switching tabs carries the
    login over, clears both status lines and focuses the first empty field.
*/
class LoginOverlay
{
    public static function present():Void
    {
        HaxeFolioApp.present("login", build, null, {geometry: {dialogWidth: StyleVars.LOGIN_OVERLAY_WIDTH, dialogHeight: StyleVars.LOGIN_OVERLAY_HEIGHT}});
    }

    private static function build(dismiss:Void->Void):OverlayContent
    {
        var submitButton:Null<ActionButton> = null;
        var tabLock:TabLock = new TabLock();
        var activeForm:Null<LoginForm> = null;

        function refreshShared():Void
        {
            if (submitButton == null || activeForm == null)
                return;

            submitButton.enabled = activeForm.canSubmit();
            tabLock.locked = activeForm.busy;
        }

        var signInForm:LoginForm = new LoginForm(false, dismiss, refreshShared);
        var registerForm:LoginForm = new LoginForm(true, dismiss, refreshShared);
        activeForm = signInForm;

        submitButton = new ActionButton(GroupedLocaleResolvers.loginOverlaySubmit(false), () -> activeForm.submit(), true);
        refreshShared();

        function onTabSelected(index:Int):Void
        {
            var previousForm:LoginForm = activeForm;
            activeForm = index == 0 ? signInForm : registerForm;

            activeForm.login = previousForm.login;
            previousForm.clearStatus();
            activeForm.clearStatus();

            submitButton.text = GroupedLocaleResolvers.loginOverlaySubmit(index == 1);
            refreshShared();

            // the page is only shown once this click has been handled
            Toolkit.callLater(activeForm.focusFirstEmpty);
        }

        var pages:Array<TabPage> = [
            {label: GroupedLocaleResolvers.loginOverlayTab(false), content: signInForm},
            {label: GroupedLocaleResolvers.loginOverlayTab(true), content: registerForm}
        ];

        // the frame is put on screen right after this factory returns
        Toolkit.callLater(signInForm.focusFirstEmpty);

        return {
            regions: [
                Header(LocaleUtils.localeBinding("intellector.overlay.login.title")),
                Tabs(Choose, pages, null, onTabSelected, tabLock),
                Actions(new ActionBar([submitButton]))
            ],
            onDismissed: () -> {
                signInForm.dispose();
                registerForm.dispose();
            }
        };
    }
}
