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
    Logging in and registering are alternative forms (a Choose region), one LoginForm per tab, under
    a fixed "Account" title (knowledge/plans/login-overlay.md §7): the tab names the mode and the
    button names the action. The overlay owns what the tabs share - the footer's primary button,
    relabelled per tab, and the tab lock held while the active form has a request in flight - and the
    cross-tab rules of §4: the Login value carries over (each tab keeps its own "Remember me"), both
    status lines clear, and focus goes to the first empty field.
*/
class LoginOverlay
{
    private static inline final DIALOG_WIDTH:Int = 430;
    private static inline final DIALOG_HEIGHT:Int = 413;

    public static function present():Void
    {
        HaxeFolioApp.present("login", build, null, {geometry: {dialogWidth: DIALOG_WIDTH, dialogHeight: DIALOG_HEIGHT}});
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

        submitButton = new ActionButton(submitLabel(false), () -> activeForm.submit(), true);
        refreshShared();

        function onTabSelected(index:Int):Void
        {
            var previousForm:LoginForm = activeForm;
            activeForm = index == 0 ? signInForm : registerForm;

            activeForm.login = previousForm.login;
            previousForm.clearStatus();
            activeForm.clearStatus();

            submitButton.text = submitLabel(index == 1);
            refreshShared();

            // the page is only shown once this click has been handled
            Toolkit.callLater(activeForm.focusFirstEmpty);
        }

        var pages:Array<TabPage> = [
            {label: LocaleUtils.localeBinding("intellector.overlay.login.tab.sign_in"), content: signInForm},
            {label: LocaleUtils.localeBinding("intellector.overlay.login.tab.register"), content: registerForm}
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

    private static function submitLabel(isSignUp:Bool):String
    {
        return LocaleUtils.localeBinding(isSignUp ? "intellector.overlay.login.submit.register" : "intellector.overlay.login.submit.sign_in");
    }
}
