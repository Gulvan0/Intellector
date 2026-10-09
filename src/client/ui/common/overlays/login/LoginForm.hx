package client.ui.common.overlays.login;

import client.auth.IdentityKeeper;
import client.auth.SavedCredentials;
import client.ui.common.overlays.login.LoginFormField;
import easyrest.GenericRestOperation;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.form.CheckBoxRow;
import haxefolio.form.TextInputField;
import http.HttpError;
import net.models.auth.AuthCredentials;
import net.models.auth.TokenResponse;
import net.rest.Rest;
import net.rest.RestOperationRegistry;

using client.ui.ComponentExtension;

/*
    One tab of `LoginOverlay`. Calls `onStateChange` after anything that could change
    `canSubmit`/`busy`, leaving the shared button and tabs to the overlay.

    A field's error shows once it has had content, or on every field after a submit attempt. The
    button is disabled on any error, so Enter is the one way to attempt: it reveals all errors.
*/
class LoginForm extends VBox
{
    private final isSignUp:Bool;
    private final restOperation:GenericRestOperation<AuthCredentials, TokenResponse>;
    private final errorReducer:HttpError->String;
    private final dismiss:Void->Void;
    private final onStateChange:Void->Void;

    private final fields:Map<LoginFormField, TextInputField> = [];
    private final fieldOrder:Array<LoginFormField>;
    private final hadContent:Map<LoginFormField, Bool> = [];
    private final rememberRow:CheckBoxRow;
    private final statusLine:Label;

    private var attempted:Bool = false;
    private var loginTaken:Bool = false;

    // disabling the fields for the request drops focus, so a failure gives it back to this one
    private var focusedOnSubmit:Null<LoginFormField> = null;

    /** Whether a request is in flight; the overlay locks the tabs meanwhile **/
    public var busy(default, null):Bool = false;

    /** Setting it isn't a user edit, but a non-empty value counts as content for error reveal **/
    public var login(get, set):String;

    public function new(isSignUp:Bool, dismiss:Void->Void, onStateChange:Void->Void)
    {
        super();

        this.isSignUp = isSignUp;
        this.restOperation = isSignUp ? RestOperationRegistry.REGISTER : RestOperationRegistry.SIGN_IN;
        this.errorReducer = isSignUp ? ErrorReducers.registerErrorSlug : ErrorReducers.signInErrorSlug;
        this.dismiss = dismiss;
        this.onStateChange = onStateChange;
        this.fieldOrder = [Login, Password];

        this.percentWidth = 100;
        this.addClass(StyleClass.LOGIN_PAGE);

        var fieldBox:VBox = new VBox();
        fieldBox.percentWidth = 100;
        fieldBox.addClass(StyleClass.LOGIN_FIELDS);
        this.addComponent(fieldBox);

        for (field in fieldOrder)
        {
            var input:TextInputField = new TextInputField(
                GroupedLocaleResolvers.loginOverlayField(field),
                text -> onFieldEdited(field, text),
                submit,
                field.mode(),
                field.maxChars()
            );
            if (field == Password)
                input.onCapsLockChange = _ -> refresh();
            fields[field] = input;
            hadContent[field] = false;
            fieldBox.addComponent(input);
        }

        var bottomBox:VBox = new VBox();
        bottomBox.percentWidth = 100;
        bottomBox.addClass(StyleClass.LOGIN_BOTTOM);
        this.addComponent(bottomBox);

        rememberRow = new CheckBoxRow(LocaleUtils.localeBinding("intellector.overlay.login.remember_me"), _ -> {}, true);
        bottomBox.addComponent(rememberRow);

        statusLine = new Label();
        statusLine.percentWidth = 100;
        statusLine.addClass(StyleClass.LOGIN_STATUS);
        bottomBox.addComponent(statusLine);

        refresh();
    }

    /** Whether nothing is in flight and no field is in error, revealed or not **/
    public function canSubmit():Bool
    {
        if (busy)
            return false;

        for (field in fieldOrder)
            if (errorSlug(field) != null)
                return false;

        return true;
    }

    /** Sends the request if valid; otherwise reveals every error, sending nothing **/
    public function submit():Void
    {
        if (busy)
            return;

        if (!canSubmit())
        {
            attempted = true;
            refresh();
            return;
        }

        focusedOnSubmit = Lambda.find(fieldOrder, field -> fields[field].focused);
        setBusy(true);

        statusLine.text = GroupedLocaleResolvers.loginOverlayInFlight(isSignUp);
        statusLine.removeClass(StyleClass.LOGIN_STATUS_ERROR);

        var payload:AuthCredentials = new AuthCredentials(login, fields[Password].currentText);
        Rest.client().execute(restOperation, onAuthSucceeded, onAuthFailed, null, null, payload);
    }

    public function clearStatus():Void
    {
        statusLine.text = "";
        statusLine.removeClass(StyleClass.LOGIN_STATUS_ERROR);
    }

    public function focusFirstEmpty():Void
    {
        for (field in fieldOrder)
        {
            if (fields[field].currentText.length == 0)
            {
                fields[field].focus();
                return;
            }
        }

        fields[fieldOrder[0]].focus();
    }

    public function dispose():Void
    {
        for (input in fields)
            input.dispose();

        rememberRow.dispose();
    }

    private function onFieldEdited(field:LoginFormField, text:String):Void
    {
        if (text.length > 0)
            hadContent[field] = true;

        if (field == Login)
            loginTaken = false;

        // a stale server message next to a corrected value reads as a second failure
        clearStatus();
        refresh();
    }

    private function onAuthSucceeded(response:TokenResponse):Void
    {
        HaxeFolioApp.valueStorage.write(LocalStorageKey.TOKEN, response.token);
        IdentityKeeper.updateIdentity(Player(response.identity.user_ref, response.identity.nickname));
        SavedCredentials.save(login, fields[Password].currentText, rememberRow.checked);
        dismiss();
    }

    private function onAuthFailed(error:HttpError):Void
    {
        setBusy(false);

        var slug:String = errorReducer(error);

        // "taken" names one field, so it goes to that field's hint rather than the status line
        if (slug == "response.login_taken")
        {
            loginTaken = true;
            clearStatus();
            refresh();
        }
        else
        {
            statusLine.text = GroupedLocaleResolvers.loginOverlayError(slug);
            statusLine.addClass(StyleClass.LOGIN_STATUS_ERROR);
        }

        if (focusedOnSubmit != null)
            fields[focusedOnSubmit].focus();
    }

    private function setBusy(value:Bool):Void
    {
        busy = value;

        for (input in fields)
            input.enabled = !value;

        rememberRow.enabled = !value;
        onStateChange();
    }

    private function errorSlug(field:LoginFormField):Null<String>
    {
        return LoginValidation.errorSlug(field, login, fields[Password].currentText, isSignUp, loginTaken);
    }

    private function refresh():Void
    {
        for (field in fieldOrder)
        {
            var input:TextInputField = fields[field];
            var slug:Null<String> = errorSlug(field);
            var revealed:Bool = attempted || hadContent[field] || (loginTaken && field == Login);
            var shownError:Null<String> = revealed ? slug : null;

            input.invalid = shownError != null;

            // the likely cause of a password error, so it replaces the error text; the red border stays
            if (input.capsLockOn)
            {
                input.hint = LocaleUtils.localeBinding("intellector.overlay.login.hint.caps_lock");
                input.hintState = Normal;
            }
            else if (shownError != null)
            {
                input.hint = GroupedLocaleResolvers.loginOverlayError(shownError);
                input.hintState = Error;
            }
            else
            {
                input.hint = fineHint(field);
                input.hintState = Normal;
            }
        }

        onStateChange();
    }

    // shown with no error; Log In shows none
    private function fineHint(field:LoginFormField):Null<String>
    {
        return isSignUp ? GroupedLocaleResolvers.loginOverlayHint(field) : null;
    }

    private function get_login():String
    {
        return fields[Login].currentText;
    }

    private function set_login(value:String):String
    {
        if (value != fields[Login].currentText)
            loginTaken = false;

        fields[Login].currentText = value;

        if (value.length > 0)
            hadContent[Login] = true;

        refresh();
        return value;
    }
}
