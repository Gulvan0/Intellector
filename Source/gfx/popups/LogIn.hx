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
        if (button != DialogButton.OK)
        {
            fn(true);
            return;
        }

        var signInMode:Bool = tabview.pageIndex == 0;
        var rawLoginText = signInMode? signInUsernameField.text : signUpUsernameField.text;
        var rawPasswordText = signInMode? signInPasswordField.text : signUpPasswordField.text;

        var login:String = rawLoginText == null? "" : StringUtils.clean(rawLoginText, StringUtils.isAlphaNumeric);
        var password:String = rawPasswordText == null? "" : StringUtils.clean(rawPasswordText, StringUtils.isAlphaNumeric);

        if (login == "") 
        {
            Dialogs.alert(Dictionary.getPhrase(LOGIN_LOGIN_NOT_SPECIFIED_WARNING_TEXT), Dictionary.getPhrase(LOGIN_WARNING_MESSAGEBOX_TITLE));
            fn(false);
            return;
        } 
        else if (password == "") 
        {
            Dialogs.alert(Dictionary.getPhrase(LOGIN_PASSWORD_NOT_SPECIFIED_WARNING_TEXT), Dictionary.getPhrase(LOGIN_WARNING_MESSAGEBOX_TITLE));
            fn(false);
            return;
        }

        if (signInMode) 
        {
            LoginManager.signin(login, password, signInRememberMeCheckbox.selected, fn.bind(true), () -> {
                Dialogs.alert(Dictionary.getPhrase(LOGIN_INVALID_PASSWORD_WARNING_TEXT), Dictionary.getPhrase(LOGIN_WARNING_MESSAGEBOX_TITLE));
                fn(false);
            });
        } 
        else
        {
            if (signUpRepeatPasswordField.text == null || signUpRepeatPasswordField.text == "")
            {
                Dialogs.alert(Dictionary.getPhrase(LOGIN_REPEATED_PASSWORD_NOT_SPECIFIED_WARNING_TEXT), Dictionary.getPhrase(LOGIN_WARNING_MESSAGEBOX_TITLE));
                fn(false);
                return;
            }

            if (login.length < 2 || login.length > 16)
            {
                Dialogs.alert(Dictionary.getPhrase(LOGIN_BAD_LOGIN_LENGTH_WARNING_TEXT), Dictionary.getPhrase(LOGIN_WARNING_MESSAGEBOX_TITLE));
                fn(false);
                return;
            }

            if (password.length < 6)
            {
                Dialogs.alert(Dictionary.getPhrase(LOGIN_BAD_PASSWORD_LENGTH_WARNING_TEXT), Dictionary.getPhrase(LOGIN_WARNING_MESSAGEBOX_TITLE));
                fn(false);
                return;
            }

            if (rawPasswordText != signUpRepeatPasswordField.text)
            {
                Dialogs.alert(Dictionary.getPhrase(LOGIN_PASSWORDS_DO_NOT_MATCH), Dictionary.getPhrase(LOGIN_WARNING_MESSAGEBOX_TITLE));
                fn(false);
                return;
            }

            LoginManager.register(login, password, signUpStayLoggedCheckbox.selected, fn.bind(true), () -> {
                Dialogs.alert(Dictionary.getPhrase(LOGIN_ALREADY_REGISTERED_WARNING_TEXT), Dictionary.getPhrase(LOGIN_WARNING_MESSAGEBOX_TITLE));
                fn(false);
            });
        }
    }
}