package client.ui.common.overlays.login;

import client.ui.common.overlays.login.LoginFormField;

/*
    The login overlay's validation rules (knowledge/plans/login-overlay.md §3): for a field, the
    slug of the first failing rule, or null. Log In is lenient (non-empty only); Register mirrors the
    server's own checks. Upper length bounds are not rules: `maxChars` makes them unreachable.

    The character check runs before "starts with a letter", so a Cyrillic login is told about the
    alphabet rather than that it should start with a letter, which it does.
*/
class LoginValidation
{
    private static inline final LOGIN_MIN_LENGTH:Int = 2;
    private static inline final PASSWORD_MIN_LENGTH:Int = 6;

    /**
        `loginTaken` is the server's verdict on the current login (Register only), cleared by the
        caller as soon as the login changes.
    **/
    public static function errorSlug(field:LoginFormField, login:String, password:String, strict:Bool, loginTaken:Bool):Null<String>
    {
        return switch field
        {
            case Login: strict ? strictLoginError(login, loginTaken) : emptyError(field, login);
            case Password: strict ? strictPasswordError(password) : emptyError(field, password);
        }
    }

    private static function emptyError(field:LoginFormField, text:String):Null<String>
    {
        return text.length == 0 ? 'empty.${field.slug()}' : null;
    }

    private static function strictLoginError(login:String, loginTaken:Bool):Null<String>
    {
        if (login.length == 0)
            return "empty.login";
        if (!~/^[A-Za-z0-9_]+$/.match(login))
            return "login.illegal_characters";
        if (!~/^[A-Za-z]/.match(login))
            return "login.not_starting_with_letter";
        if (login.length < LOGIN_MIN_LENGTH)
            return "login.too_short";
        if (login.indexOf("__") != -1)
            return "login.double_underscore";
        if (StringTools.endsWith(login, "_"))
            return "login.trailing_underscore";
        if (loginTaken)
            return "response.login_taken";

        return null;
    }

    private static function strictPasswordError(password:String):Null<String>
    {
        if (password.length == 0)
            return "empty.password";
        if (password.length < PASSWORD_MIN_LENGTH)
            return "password.too_short";

        return null;
    }
}
