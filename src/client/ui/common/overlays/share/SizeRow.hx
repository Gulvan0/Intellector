package client.ui.common.overlays.share;

import client.datatypes.share.ExportSettings;
import client.logic.share.ExportSettingsRules;
import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.ResponsivityController;
import haxefolio.appearance.AppearanceContext;
import haxefolio.form.TextInputField;
import haxefolio.form.plumbing.HintState;
import morestd.Detachable;

/**
    Width and height, each with its range or error in its header, and between them the toggle that
    keeps their proportions. The two fields are always equally wide.
**/
class SizeRow extends HBox
{
    private final settings:ExportSettings;
    private final onEdit:Void->Void;
    private final widthField:TextInputField;
    private final heightField:TextInputField;
    private final linkToggle:Button;
    private final bindings:Array<Detachable> = [];

    /** A disabled row greys out in place and ignores input **/
    public var enabled(default, set):Bool = true;

    public function new(settings:ExportSettings, onEdit:Void->Void)
    {
        super();

        this.settings = settings;
        this.onEdit = onEdit;
        this.percentWidth = 100;
        this.horizontalSpacing = 0;

        widthField = sizeField("intellector.overlay.share.width", onWidthTyped);
        this.addComponent(widthField);

        var linkColumn:VBox = new VBox();
        linkColumn.verticalSpacing = 0;
        linkColumn.paddingTop = AppearanceContext.current.geometry.messageLine + StyleVars.SHARE_LABEL_GAP;
        this.addComponent(linkColumn);

        linkToggle = new Button();
        linkToggle.percentWidth = 100;
        linkToggle.addClass(StyleClass.SHARE_LINK_TOGGLE);
        linkToggle.tooltip = LocaleUtils.localeBinding("intellector.overlay.share.keep_proportions");
        linkToggle.element.setAttribute("aria-label", LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.overlay.share.keep_proportions")));
        linkToggle.onClick = _ -> toggleLink();
        linkColumn.addComponent(linkToggle);

        heightField = sizeField("intellector.overlay.share.height", onHeightTyped);
        this.addComponent(heightField);

        bindings.push(ResponsivityController.bind(StyleVars.SHARE_LINK_TOGGLE_WIDTH, width -> linkColumn.width = width));
        bindings.push(ResponsivityController.bind(AppearanceContext.current.geometry.fieldHeight, height -> linkToggle.height = height));

        render();
    }

    public function dispose():Void
    {
        widthField.dispose();
        heightField.dispose();
        for (binding in bindings)
            binding.detach();
    }

    private function sizeField(labelKey:String, onTyped:String->Void):TextInputField
    {
        var field:Null<TextInputField> = null;
        field = new TextInputField(LocaleUtils.localeBinding(labelKey), text -> {
            var digits:String = ExportSettingsRules.digitsOnly(text);
            if (digits != text)
                field.currentText = digits;
            onTyped(digits);
        }, null, Plain, ExportSettingsRules.MAX_DIGITS);
        field.percentWidth = 50;
        field.addClass(StyleClass.SHARE_MONO);
        field.setSuffix(LocaleUtils.localeBinding("intellector.overlay.share.px"), StyleVars.SHARE_UNIT_LANE_WIDTH);
        field.setNumericKeyboard(true);
        return field;
    }

    private function onWidthTyped(text:String):Void
    {
        ExportSettingsRules.setWidth(settings, text);
        render();
        onEdit();
    }

    private function onHeightTyped(text:String):Void
    {
        ExportSettingsRules.setHeight(settings, text);
        render();
        onEdit();
    }

    private function toggleLink():Void
    {
        if (!enabled)
            return;

        ExportSettingsRules.setLinked(settings, !settings.linked);
        render();
        onEdit();
    }

    private function render():Void
    {
        if (widthField.currentText != settings.widthText)
            widthField.currentText = settings.widthText;
        if (heightField.currentText != settings.heightText)
            heightField.currentText = settings.heightText;

        renderValidity(widthField, ExportSettingsRules.parseSize(settings.widthText) != null);
        renderValidity(heightField, ExportSettingsRules.parseSize(settings.heightText) != null);

        linkToggle.icon = Assets.controlIcon(settings.linked ? "link_on" : "link_off");
        linkToggle.element.setAttribute("aria-pressed", settings.linked ? "true" : "false");
    }

    private static function renderValidity(field:TextInputField, valid:Bool):Void
    {
        field.hint = LocaleUtils.localeBinding(valid ? "intellector.overlay.share.size.constraint" : "intellector.overlay.share.size.error");
        field.hintState = valid ? Normal : Error;
        field.invalid = !valid;
    }

    private function set_enabled(value:Bool):Bool
    {
        enabled = value;
        widthField.enabled = value;
        heightField.enabled = value;
        linkToggle.disabled = !value;
        return value;
    }
}
