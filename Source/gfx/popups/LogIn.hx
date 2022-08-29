package gfx.popups;

import utils.StringUtils;
import gfx.Dialogs;
import dict.Dictionary;
import haxe.ui.containers.dialogs.Dialog;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/menubar/popups/login_popup.xml"))
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
            Dialogs.alert(LOGIN_LOGIN_NOT_SPECIFIED_WARNING_TEXT, LOGIN_WARNING_MESSAGEBOX_TITLE);
            fn(false);
            return;
        } 
        else if (password == "") 
        {
            Dialogs.alert(LOGIN_PASSWORD_NOT_SPECIFIED_WARNING_TEXT, LOGIN_WARNING_MESSAGEBOX_TITLE);
            fn(false);
            return;
        }

        if (signInMode) 
        {
            LoginManager.signin(login, password, signInRememberMeCheckbox.selected, fn.bind(true), () -> {
                Dialogs.alert(LOGIN_INVALID_PASSWORD_WARNING_TEXT, LOGIN_WARNING_MESSAGEBOX_TITLE);
                fn(false);
            });
        } 
        else
        {
            if (signUpRepeatPasswordField.text == null || signUpRepeatPasswordField.text == "")
            {
                Dialogs.alert(LOGIN_REPEATED_PASSWORD_NOT_SPECIFIED_WARNING_TEXT, LOGIN_WARNING_MESSAGEBOX_TITLE);
                fn(false);
                return;
            }

            if (login.length < 2 || login.length > 16)
            {
                Dialogs.alert(LOGIN_BAD_LOGIN_LENGTH_WARNING_TEXT, LOGIN_WARNING_MESSAGEBOX_TITLE);
                fn(false);
                return;
            }

            if (password.length < 6)
            {
                Dialogs.alert(LOGIN_BAD_PASSWORD_LENGTH_WARNING_TEXT, LOGIN_WARNING_MESSAGEBOX_TITLE);
                fn(false);
                return;
            }

            if (rawPasswordText != signUpRepeatPasswordField.text)
            {
                Dialogs.alert(LOGIN_PASSWORDS_DO_NOT_MATCH, LOGIN_WARNING_MESSAGEBOX_TITLE);
                fn(false);
                return;
            }

            LoginManager.register(login, password, signUpStayLoggedCheckbox.selected, fn.bind(true), () -> {
                Dialogs.alert(LOGIN_ALREADY_REGISTERED_WARNING_TEXT, LOGIN_WARNING_MESSAGEBOX_TITLE);
                fn(false);
            });
        }
    }
}