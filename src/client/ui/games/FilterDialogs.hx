package client.ui.games;

import haxe.ui.Toolkit;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.appearance.AppearanceOverrides;
import haxefolio.form.TextInputField;
import haxefolio.structure.ActionBar;
import haxefolio.structure.ActionButton;
import js.lib.RegExp;

using StringTools;

/** The game database's dialogs: naming a filter to save, confirming its overwrite, confirming a deletion **/
class FilterDialogs
{
    private static inline final DIALOG_WIDTH:Int = 420;
    private static inline final NAME_BODY_HEIGHT:Int = 118;
    private static inline final CONFIRM_BODY_HEIGHT:Int = 96;
    private static inline final HEADER_HEIGHT:Int = 60;
    private static inline final ACTIONS_HEIGHT:Int = 68;
    private static final NAME_PATTERN:RegExp = new RegExp("^[\\p{L}\\p{N}_ ]{1,32}$", "u");

    /** A saved filter's name as typed, if valid: trimmed, letters, digits, spaces and `_`, up to 32 **/
    public static function validName(text:String):Null<String>
    {
        var name:String = text.trim();
        return NAME_PATTERN.test(name) ? name : null;
    }

    /** Asks for a name, `initial` filled in; `onName` gets a valid one **/
    public static function askName(initial:String, onName:String->Void):Void
    {
        HaxeFolioApp.present("save-filter", dismiss -> {
            var field:Null<TextInputField> = null;
            var saveButton:Null<ActionButton> = null;

            var submit:Void->Void = () -> {
                var name:Null<String> = validName(field.currentText);
                if (name == null)
                    return;
                dismiss();
                onName(name);
            };

            var refresh:Void->Void = () -> {
                var text:String = field.currentText.trim();
                var invalid:Bool = text != "" && validName(text) == null;
                field.invalid = invalid;
                field.hintState = invalid ? Error : Normal;
                saveButton.enabled = validName(text) != null;
            };

            field = new TextInputField(LocaleUtils.localeBinding("intellector.games.save.name"), _ -> refresh(), submit);
            field.percentWidth = 100;
            field.hint = LocaleUtils.localeBinding("intellector.games.save.hint");
            field.currentText = initial;
            field.selectAllOnFocus = true;
            saveButton = new ActionButton(LocaleUtils.localeBinding("intellector.games.save.submit"), submit, true);
            refresh();
            Toolkit.callLater(field.focus);

            return {
                regions: [
                    Header(LocaleUtils.localeBinding("intellector.games.save.title")),
                    Custom(NAME_BODY_HEIGHT, body(field)),
                    Actions(new ActionBar([new ActionButton(LocaleUtils.localeBinding("intellector.games.dialog.cancel"), dismiss), saveButton]))
                ]
            };
        }, null, geometry(NAME_BODY_HEIGHT));
    }

    /** Confirms replacing the user's filter named `name` **/
    public static function confirmOverwrite(name:String, onConfirmed:Void->Void):Void
    {
        confirm("replace-filter", "intellector.games.replace.title", "intellector.games.replace.text", "intellector.games.replace.submit", name, onConfirmed);
    }

    /** Confirms deleting the user's filter named `name` **/
    public static function confirmDeletion(name:String, onConfirmed:Void->Void):Void
    {
        confirm("delete-filter", "intellector.games.delete.title", "intellector.games.delete.text", "intellector.games.delete.submit", name, onConfirmed);
    }

    private static function confirm(slug:String, titleKey:String, textKey:String, submitKey:String, name:String, onConfirmed:Void->Void):Void
    {
        HaxeFolioApp.present(slug, dismiss -> {
            var text:Label = new Label();
            text.percentWidth = 100;
            text.text = LocaleUtils.localeBinding(textKey);
            text.addClass(StyleClass.GAMES_DIALOG_TEXT);

            var submit:ActionButton = new ActionButton(LocaleUtils.localeBinding(submitKey), () -> {
                dismiss();
                onConfirmed();
            }, true);
            return {
                regions: [
                    Header(LocaleUtils.resolveText(LocaleUtils.localeBinding(titleKey), name)),
                    Custom(CONFIRM_BODY_HEIGHT, body(text)),
                    Actions(new ActionBar([new ActionButton(LocaleUtils.localeBinding("intellector.games.dialog.cancel"), dismiss), submit]))
                ]
            };
        }, null, geometry(CONFIRM_BODY_HEIGHT));
    }

    /** A dialog's padded body holding `content` **/
    public static function body(content:Component):VBox
    {
        var box:VBox = new VBox();
        box.percentWidth = 100;
        box.percentHeight = 100;
        box.addClass(StyleClass.GAMES_DIALOG_BODY);
        box.addComponent(content);
        return box;
    }

    /** A dialog of the header, a body `bodyHeight` tall and the action bar **/
    public static function geometry(bodyHeight:Int):AppearanceOverrides
    {
        return {geometry: {dialogWidth: DIALOG_WIDTH, dialogHeight: HEADER_HEIGHT + bodyHeight + ACTIONS_HEIGHT}};
    }
}
