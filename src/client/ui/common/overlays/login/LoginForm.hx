package client.ui.common.overlays.login;

import haxe.ui.components.Label;
import haxe.ui.validators.IValidator;
import haxe.ui.events.MouseEvent;
import net.rest.RestOperationRegistry;
import easyrest.GenericRestOperation;
import client.auth.SavedCredentials;
import client.auth.IdentityKeeper;
import haxefolio.HaxeFolioApp;
import net.models.auth.TokenResponse;
import net.rest.Rest;
import net.models.auth.AuthCredentials;
import http.HttpError;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;
import haxefolio.LocaleUtils;
import client.ui.common.overlays.login.LoginFormField;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/common/overlays/login/login_form.xml"))
class LoginForm extends VBox
{
    private final restOperation:GenericRestOperation<AuthCredentials, TokenResponse>;
    private final errorReducer:HttpError->String;
    private final dismissCallback:Void->Void;

    private final inputBoxes:Map<LoginFormField, TextFieldInputBox> = [];

    public function new(formSlug:String, isSignUp:Bool, dismissCallback:Void->Void)
    {
        super();

        this.restOperation = isSignUp? RestOperationRegistry.REGISTER : RestOperationRegistry.SIGN_IN;
        this.errorReducer = isSignUp? ErrorReducers.registerErrorSlug : ErrorReducers.signInErrorSlug;
        this.dismissCallback = dismissCallback;

        addRow(Login, isSignUp);
        addRow(Password, isSignUp);
        if (isSignUp)
            addRow(RepeatPassword, isSignUp);

        submitButton.text = LocaleUtils.localeBinding('intellector.overlay.login.submit.$formSlug');
    }

    private function addRow(field:LoginFormField, isValidationStrict:Bool):Void
    {
        var fieldNameLabel:Label = new Label();
        fieldNameLabel.text = LocaleUtils.localeBinding('intellector.overlay.login.field.${field.slug()}');
        fieldNameLabel.addClass('intellector-login-form-field-label');

        var validators:Array<IValidator> = ValidatorRegistry.getValidators(field, isValidationStrict);
        var externalValidators:Array<String->Null<String>> = [];
        if (field == RepeatPassword)
            externalValidators.push(
                repeatPasswordText -> inputBoxes[Password].getText() != repeatPasswordText? GroupedLocaleResolvers.loginOverlayError("passwords_do_not_match") : null
            );
        var inputBox:TextFieldInputBox = new TextFieldInputBox(validators, externalValidators, field.restrictChars(), field.maxChars(), field.obscured());

        rowsContainer.addComponent(fieldNameLabel);
        rowsContainer.addComponent(inputBox);

        inputBoxes[field] = inputBox;
    }

    private function completeAuth(response:TokenResponse):Void
    {
        HaxeFolioApp.valueStorage.write(LocalStorageKey.TOKEN, response.token);
        IdentityKeeper.updateIdentity(Player(response.identity.user_ref, response.identity.nickname));
        SavedCredentials.save(inputBoxes[Login].getText(), inputBoxes[Password].getText(), rememberCheckbox.selected);
        dismissCallback();
    }

    private function onHttpError(error:HttpError):Void
    {
        submitButton.disabled = false;

        errorLabel.text = GroupedLocaleResolvers.loginOverlayError(errorReducer(error));
        errorLabel.hidden = false;
    }

    @:bind(submitButton, MouseEvent.CLICK)
    private function onSubmitPressed(_):Void
    {
        errorLabel.hidden = true;

        var areFieldsValid:Bool = true;
        for (box in inputBoxes)
            areFieldsValid = box.revalidate(true) && areFieldsValid;  // revalidate() first so it's never short-circuited away; every invalid box gets its error shown, not just the first one

        if (!areFieldsValid)
            return;

        submitButton.disabled = true;

        var payload:AuthCredentials = new AuthCredentials(inputBoxes[Login].getText(), inputBoxes[Password].getText());
        Rest.client().execute(restOperation, completeAuth, onHttpError, null, null, payload);
    }
}
