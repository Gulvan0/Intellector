package client.ui.common.overlays.login;

import haxefolio.form.TextInputMode;

@:using(client.ui.common.overlays.login.LoginFormField.LoginFormFieldExtension)
enum LoginFormField
{
    Login;
    Password;
}

class LoginFormFieldExtension
{
    public static inline function mode(field:LoginFormField):TextInputMode
    {
        return switch field
        {
            case Login: Plain;
            case Password: RevealablePassword;
        }
    }

    public static inline function slug(field:LoginFormField):String
    {
        return switch field
        {
            case Login: "login";
            case Password: "password";
        }
    }

    public static inline function maxChars(field:LoginFormField):Int
    {
        return switch field
        {
            case Login: 32;
            case Password: 128;
        }
    }
}
