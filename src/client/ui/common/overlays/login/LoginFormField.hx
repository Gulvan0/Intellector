package client.ui.common.overlays.login;

@:using(client.ui.common.overlays.login.LoginFormField.LoginFormFieldExtension)
enum LoginFormField
{
    Login;
    Password;
    RepeatPassword;
}

class LoginFormFieldExtension
{
    public static inline function obscured(field:LoginFormField):Bool
    {
        return field != Login;
    }

    public static inline function slug(field:LoginFormField):String
    {
        return switch field
        {
            case Login: "login";
            case Password: "password";
            case RepeatPassword: "repeat_password";
        }
    }

    public static inline function restrictChars(field:LoginFormField):Null<String>
    {
        return switch field
        {
            case Login: "A-Za-z0-9_";
            default: null;
        }
    }

    public static inline function minChars(field:LoginFormField):Int
    {
        return switch field
        {
            case Login: 2;
            case Password: 6;
            case RepeatPassword: 6;
        }
    }

    public static inline function maxChars(field:LoginFormField):Int
    {
        return switch field
        {
            case Login: 32;
            case Password: 128;
            case RepeatPassword: 128;
        }
    }
}
