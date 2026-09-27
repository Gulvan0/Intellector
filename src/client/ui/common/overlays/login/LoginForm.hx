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

/*
    One tab page of LoginOverlay (knowledge/plans/login-overlay.md §2-§4): the fields, then 18px
    below the last one the checkbox and the always-reserved status line. Both tabs have the same two
    fields (the password one revealable, which is why Register has no "repeat password"), so the
    page takes its natural height and the two tabs match.

    The password field's slot says "Caps Lock is on" while it is focused with Caps Lock on, over its
    hint or error alike.

    The form owns its validation state. It never touches the overlay's shared primary button or the
    tab strip: it calls `onStateChange` after anything that could change `canSubmit`/`busy`, and the
    overlay reads them back.

    Error reveal: a field's error shows once the field has had content, or on every field once a
    submit was attempted on this tab. The primary is disabled on any error, revealed or not, so Enter
    on an invalid form is the one way to "attempt" - it reveals all errors and sends nothing.
*/
class LoginForm extends VBox
{
    private static inline final FIELD_SPACING:Int = 14;
    private static inline final BOTTOM_SPACING:Int = 4;
    private static inline final GAP_ABOVE_BOTTOM:Int = 18;

    // 22 on the left; 12 on the right plus the scroll area's reserved 10px lane makes 22 visible too
    private static inline final PADDING_TOP:Int = 18;
    private static inline final PADDING_RIGHT:Int = 12;
    private static inline final PADDING_BOTTOM:Int = 14;
    private static inline final PADDING_LEFT:Int = 22;

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

    /**
        Whether a request is in flight. The overlay locks the tabs while it is.
    **/
    public var busy(default, null):Bool = false;

    /**
        What the Login field holds. Assigning it (e.g. to carry it over from the other tab) does
        not count as the user's edit, but a non-empty value counts as content for error reveal.
    **/
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
        this.verticalSpacing = 0;
        this.paddingTop = PADDING_TOP;
        this.paddingRight = PADDING_RIGHT;
        this.paddingBottom = PADDING_BOTTOM;
        this.paddingLeft = PADDING_LEFT;
        this.addClass("intellector-login-page");

        var fieldBox:VBox = new VBox();
        fieldBox.percentWidth = 100;
        fieldBox.verticalSpacing = FIELD_SPACING;
        this.addComponent(fieldBox);

        for (field in fieldOrder)
        {
            var input:TextInputField = new TextInputField(
                LocaleUtils.localeBinding('intellector.overlay.login.field.${field.slug()}'),
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
        bottomBox.marginTop = GAP_ABOVE_BOTTOM;
        bottomBox.verticalSpacing = BOTTOM_SPACING;
        this.addComponent(bottomBox);

        rememberRow = new CheckBoxRow(LocaleUtils.localeBinding("intellector.overlay.login.remember_me"), _ -> {}, true);
        bottomBox.addComponent(rememberRow);

        statusLine = new Label();
        statusLine.percentWidth = 100;
        statusLine.addClass("intellector-login-status");
        bottomBox.addComponent(statusLine);

        refresh();
    }

    /**
        Whether the primary action may be pressed: nothing in flight and no field in error
        (revealed or not).
    **/
    public function canSubmit():Bool
    {
        if (busy)
            return false;

        for (field in fieldOrder)
            if (errorSlug(field) != null)
                return false;

        return true;
    }

    /**
        Sends the request if the form is valid; otherwise reveals every error on this tab and
        sends nothing. Called by the overlay's primary button and by Enter in any field.
    **/
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
        showStatus(LocaleUtils.localeBinding(isSignUp ? "intellector.overlay.login.in_flight.register" : "intellector.overlay.login.in_flight.sign_in"), false);

        var payload:AuthCredentials = new AuthCredentials(login, fields[Password].currentText);
        Rest.client().execute(restOperation, onAuthSucceeded, onAuthFailed, null, null, payload);
    }

    public function clearStatus():Void
    {
        showStatus("", false);
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
            showStatus(GroupedLocaleResolvers.loginOverlayError(slug), true);

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

    private function showStatus(text:String, isError:Bool):Void
    {
        statusLine.text = text;

        if (isError)
            statusLine.addClass("intellector-login-status-error");
        else
            statusLine.removeClass("intellector-login-status-error");
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

            // the likely cause of a password error while typing, so it takes the slot over the error; the red border stays
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

    // What a field's slot says while it shows no error. Log In says nothing while fine.
    private function fineHint(field:LoginFormField):Null<String>
    {
        if (!isSignUp)
            return null;

        return switch field {
            case Login: LocaleUtils.localeBinding("intellector.overlay.login.hint.login");
            case Password: LocaleUtils.localeBinding("intellector.overlay.login.hint.password");
        }
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
