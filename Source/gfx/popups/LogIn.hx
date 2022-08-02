package gfx.popups;

import utils.StringUtils;
import gfx.components.Dialogs;
import net.LoginManager;
import dict.Dictionary;
import haxe.ui.containers.dialogs.Dialog;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/basic/popups/login_popup.xml"))
class LogIn extends Dialog 
{
    public function new() 
    {
        super();
        buttons = DialogButton.CANCEL | DialogButton.OK;
    }
    
    public override function validateDialog(button:DialogButton, fn:Bool->Void) 
    {
        var login:String = StringUtils.clean(loginField.text, StringUtils.isAlphaNumeric);
        var password:String = StringUtils.clean(passwordField.text, StringUtils.isAlphaNumeric);

        if (button != DialogButton.OK)
        {
            fn(true);
            return;
        }

        if (login == "" || login == null) 
        {
            Dialogs.alert(Dictionary.getPhrase(LOGIN_LOGIN_NOT_SPECIFIED_WARNING_TEXT), Dictionary.getPhrase(LOGIN_WARNING_MESSAGEBOX_TITLE));
            fn(false);
            return;
        } 
        else if (password == "" || password == null) 
        {
            Dialogs.alert(Dictionary.getPhrase(LOGIN_PASSWORD_NOT_SPECIFIED_WARNING_TEXT), Dictionary.getPhrase(LOGIN_WARNING_MESSAGEBOX_TITLE));
            fn(false);
            return;
        }

        if (loginModeBtn.selected) 
        {
            LoginManager.signin(login, password, rememberMeCheckbox.selected, fn.bind(true), () -> {
                Dialogs.alert(Dictionary.getPhrase(LOGIN_INVALID_PASSWORD_WARNING_TEXT), Dictionary.getPhrase(LOGIN_WARNING_MESSAGEBOX_TITLE));
                fn(false);
            });
        } 
        else
        {
            if (login.length < 2 || login.length > 16)
            {
                Dialogs.alert(Dictionary.getPhrase(LOGIN_BAD_LOGIN_LENGTH_WARNING_TEXT), Dictionary.getPhrase(LOGIN_WARNING_MESSAGEBOX_TITLE));
                fn(false);
                return;
            }

            LoginManager.register(login, password, rememberMeCheckbox.selected, fn.bind(true), () -> {
                Dialogs.alert(Dictionary.getPhrase(LOGIN_ALREADY_REGISTERED_WARNING_TEXT), Dictionary.getPhrase(LOGIN_WARNING_MESSAGEBOX_TITLE));
                fn(false);
            });
        }
    }
}