package client.ui.common.overlays.login;

import haxe.ui.validators.IValidator;
import haxe.ui.validators.RequiredValidator;
import haxe.ui.validators.PatternValidator;
import client.ui.common.overlays.login.LoginFormField;

class ValidatorRegistry
{
    public static function getValidators(field:LoginFormField, strict:Bool):Array<IValidator>
    {
        return switch field {
            case Login: loginValidators(strict);
            case Password: passwordValidators(strict);
            case RepeatPassword: repeatPasswordValidators();
        }
    }

    private static function loginValidators(strict:Bool):Array<IValidator>
    {
        var validators:Array<IValidator> = [requiredValidator(Login)];

        if (strict)
        {
            // Validators below are together equivalent to the server's own validation
            validators.push(lengthValidator(Login));
            validators.push(patternValidator(~/^[a-zA-Z]/, "login_does_not_start_with_letter"));
            validators.push(patternValidator(~/^[a-zA-Z0-9_]+$/, "login_forbidden_char"));
            validators.push(patternValidator(~/^(?!.*__).*$/, "login_consecutive_underscores"));
            validators.push(patternValidator(~/[^_]$/, "login_ends_with_underscore"));
        }

        return validators;
    }

    private static function passwordValidators(strict:Bool):Array<IValidator>
    {
        var validators:Array<IValidator> = [requiredValidator(Password)];

        if (strict)
            validators.push(lengthValidator(Password));

        return validators;
    }

    private static function repeatPasswordValidators():Array<IValidator>
    {
        return [requiredValidator(RepeatPassword)];
    }

    private static function lengthValidator(field:LoginFormField):IValidator
    {
        var ereg:EReg = new EReg('^.{${field.minChars()},${field.maxChars()}}$', "");
        return patternValidator(ereg, 'invalid_length.' + field.slug());
    }

    private static function requiredValidator(field:LoginFormField):IValidator
    {
        var validator:RequiredValidator = new RequiredValidator();
        validator.applyValid = false;
        validator.invalidMessage = GroupedLocaleResolvers.loginOverlayError('empty.' + field.slug());
        return validator;
    }

    private static function patternValidator(pattern:EReg, errorSlug:String):IValidator
    {
        var validator:PatternValidator = new PatternValidator();
        validator.applyValid = false;
        validator.pattern = pattern;
        validator.invalidMessage = GroupedLocaleResolvers.loginOverlayError(errorSlug);
        return validator;
    }
}
