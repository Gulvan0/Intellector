package client.ui.common.overlays.login;

import haxefolio.HaxeFolioApp;
import haxefolio.overlay.OverlayContent;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/common/overlays/login/login_overlay.xml"))
class LoginOverlay extends OverlayContent
{
    public function new(dismiss:Void->Void)
    {
        super();
        signInTab.addComponent(new LoginForm("sign_in", false, dismiss));
        registerTab.addComponent(new LoginForm("register", true, dismiss));
    }
}
