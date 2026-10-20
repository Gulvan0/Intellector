package client.ui.common.overlays.share;

import client.datatypes.share.ExportSettings;
import client.logic.share.ExportSettingsRules;
import client.ui.common.board.export.BoardAnimation;
import client.ui.common.board.export.BoardRaster;
import client.ui.common.board.export.BoardRaster.BoardPicture;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.ResponsivityController;
import haxefolio.appearance.AppearanceContext;
import haxefolio.browser.FileDownload;
import haxefolio.form.CheckBoxRow;
import haxefolio.form.ColorField;
import haxefolio.form.TextInputField;
import haxefolio.form.plumbing.ChoiceButton;
import haxefolio.form.plumbing.FieldHeader;
import haxefolio.form.plumbing.HintState;
import haxefolio.form.plumbing.IconAlign;
import haxefolio.structure.ActionButton;
import js.html.Blob;
import morestd.Detachable;

/**
    One export's settings beside a preview of its result, and the button that downloads it. Every
    change shows in the preview at once; the button is disabled while a value in use is invalid or
    an export is in progress, and the settings are locked meanwhile. Wide, the preview is on the
    left; collapsed, above the settings.
**/
class ExportPanel extends Box
{
    private final settings:ExportSettings;
    private final frames:ExportSettings->Array<BoardPicture>;
    private final fileName:String;
    private final hasLastMove:Bool;
    private final preview:ExportPreview;
    private final sizeRow:SizeRow;
    private final colorField:ColorField;
    private final transparentToggle:Null<ChoiceButton>;
    private final intervalField:Null<TextInputField>;
    private final labelsRow:CheckBoxRow;
    private final highlightRow:Null<CheckBoxRow>;
    private final downloadButton:ActionButton;
    private final bindings:Array<Detachable> = [];
    private var animation:Null<BoardAnimation> = null;
    private var busy:Bool = false;
    private var disposed:Bool = false;

    /**
        `frames` are what the export draws from the settings: one picture for an image, every frame
        for an animation (the preview shows the last). `hasLastMove`: whether the image's position
        has a last move to highlight.
    **/
    public function new(settings:ExportSettings, frames:ExportSettings->Array<BoardPicture>, fileName:String, hasLastMove:Bool, collapsed:Bool)
    {
        super();

        this.settings = settings;
        this.frames = frames;
        this.fileName = fileName;
        this.hasLastMove = hasLastMove;
        this.percentWidth = 100;
        this.addClass(StyleClass.SHARE_PANEL);

        var isImage:Bool = settings.kind == Image;

        var column:VBox = new VBox();
        column.addClass(StyleClass.SHARE_SETTINGS);

        sizeRow = new SizeRow(settings, refresh);
        column.addComponent(sizeRow);

        colorField = new ColorField(
            LocaleUtils.localeBinding("intellector.overlay.share.background"),
            settings.backgroundText,
            onBackgroundTyped,
            LocaleUtils.localeBinding("intellector.overlay.share.not_used")
        );
        colorField.addClass(StyleClass.SHARE_MONO);

        if (isImage)
        {
            var backgroundRow:HBox = new HBox();
            backgroundRow.percentWidth = 100;
            backgroundRow.horizontalSpacing = 8;
            backgroundRow.addComponent(colorField);

            transparentToggle = new ChoiceButton(LocaleUtils.localeBinding("intellector.overlay.share.transparent"), onTransparentToggled, null, Leading, settings.transparent);
            transparentToggle.width = StyleVars.SHARE_TRANSPARENT_WIDTH;
            transparentToggle.verticalAlign = "bottom";
            transparentToggle.addClass(StyleClass.SHARE_TRANSPARENT);
            backgroundRow.addComponent(transparentToggle);

            column.addComponent(backgroundRow);
        }
        else
        {
            transparentToggle = null;
            column.addComponent(colorField);
        }

        if (isImage)
            intervalField = null;
        else
        {
            var field:Null<TextInputField> = null;
            field = new TextInputField(LocaleUtils.localeBinding("intellector.overlay.share.interval"), text -> {
                var digits:String = ExportSettingsRules.digitsOnly(text);
                if (digits != text)
                    field.currentText = digits;
                settings.intervalText = digits;
                refresh();
            }, null, Plain, ExportSettingsRules.MAX_DIGITS);
            field.currentText = settings.intervalText;
            field.addClass(StyleClass.SHARE_MONO);
            field.setSuffix(LocaleUtils.localeBinding("intellector.overlay.share.ms"), StyleVars.SHARE_UNIT_LANE_WIDTH);
            field.setNumericKeyboard(true);
            intervalField = field;
            column.addComponent(field);
        }

        var otherGroup:VBox = new VBox();
        otherGroup.percentWidth = 100;
        otherGroup.verticalSpacing = 0;
        var otherHeader:FieldHeader = new FieldHeader(LocaleUtils.localeBinding("intellector.overlay.share.other"));
        otherHeader.height = AppearanceContext.current.geometry.messageLine;
        otherGroup.addComponent(otherHeader);

        labelsRow = new CheckBoxRow(LocaleUtils.localeBinding("intellector.overlay.share.labels"), checked -> {
            settings.labels = checked;
            refresh();
        }, settings.labels);
        otherGroup.addComponent(labelsRow);

        if (isImage)
        {
            highlightRow = new CheckBoxRow(LocaleUtils.localeBinding("intellector.overlay.share.highlight"), checked -> {
                settings.highlightLastMove = checked;
                refresh();
            }, settings.highlightLastMove && hasLastMove, hasLastMove);
            otherGroup.addComponent(highlightRow);
        }
        else
            highlightRow = null;

        column.addComponent(otherGroup);

        downloadButton = new ActionButton(downloadLabel(), download, true);
        downloadButton.percentWidth = 100;
        column.addComponent(downloadButton);

        bindings.push(ResponsivityController.bind(AppearanceContext.current.geometry.fieldHeight, height -> {
            downloadButton.height = height;
            if (transparentToggle != null)
                transparentToggle.height = height;
        }));

        var previewHeight:Int = collapsed ? StyleVars.SHARE_NARROW_PREVIEW_HEIGHT : ShareLayout.settingsHeight(settings.kind, AppearanceContext.current.geometry.fieldHeight.resolve(false));
        preview = new ExportPreview(previewHeight);

        var layout:Box = collapsed ? new VBox() : new HBox();
        layout.percentWidth = 100;
        if (collapsed)
        {
            (cast layout : VBox).verticalSpacing = StyleVars.SHARE_PANEL_GAP;
            column.percentWidth = 100;
        }
        else
        {
            (cast layout : HBox).horizontalSpacing = StyleVars.SHARE_PANEL_GAP;
            column.width = StyleVars.SHARE_SETTINGS_WIDTH;
        }
        layout.addComponent(preview);
        layout.addComponent(column);
        this.addComponent(layout);

        refresh();
    }

    /** Stops an export in progress and releases what the panel holds **/
    public function dispose():Void
    {
        disposed = true;
        if (animation != null)
            animation.cancel();

        preview.dispose();
        sizeRow.dispose();
        colorField.dispose();
        if (intervalField != null)
            intervalField.dispose();
        labelsRow.dispose();
        if (highlightRow != null)
            highlightRow.dispose();
        for (binding in bindings)
            binding.detach();
    }

    private function onBackgroundTyped(text:String):Void
    {
        ExportSettingsRules.setBackground(settings, text);
        refresh();
    }

    private function onTransparentToggled():Void
    {
        settings.transparent = transparentToggle.selected;
        refresh();
    }

    private function refresh():Void
    {
        var backgroundInvalid:Bool = ExportSettingsRules.backgroundInvalid(settings);
        colorField.enabled = ExportSettingsRules.effectiveBackground(settings) != null;
        colorField.hint = backgroundInvalid ? LocaleUtils.localeBinding("intellector.overlay.share.background.error") : null;
        colorField.hintState = backgroundInvalid ? Error : Normal;
        colorField.invalid = backgroundInvalid;

        if (intervalField != null)
        {
            var intervalValid:Bool = ExportSettingsRules.parseInterval(settings.intervalText) != null;
            intervalField.hint = LocaleUtils.localeBinding(intervalValid ? "intellector.overlay.share.interval.constraint" : "intellector.overlay.share.interval.error");
            intervalField.hintState = intervalValid ? Normal : Error;
            intervalField.invalid = !intervalValid;
        }

        sizeRow.enabled = !busy;
        colorField.locked = busy;
        if (transparentToggle != null)
            transparentToggle.disabled = busy;
        if (intervalField != null)
            intervalField.enabled = !busy;
        labelsRow.enabled = !busy;
        if (highlightRow != null)
            highlightRow.enabled = !busy && hasLastMove;

        downloadButton.enabled = !busy && ExportSettingsRules.isValid(settings);
        if (!busy)
            downloadButton.text = downloadLabel();

        var pictures:Array<BoardPicture> = frames(settings);
        preview.display(pictures[pictures.length - 1], settings.lastValidWidth, settings.lastValidHeight);
    }

    private function download():Void
    {
        if (busy || !ExportSettingsRules.isValid(settings))
            return;

        var width:Int = ExportSettingsRules.parseSize(settings.widthText);
        var height:Int = ExportSettingsRules.parseSize(settings.heightText);
        var pictures:Array<BoardPicture> = frames(settings);

        setBusy(true);

        switch settings.kind
        {
            case Image:
                BoardRaster.draw(pictures[0], width, height, canvas -> canvas.toBlob(onExported, "image/png"));
            case Animation:
                downloadButton.text = progressLabel(0);
                animation = new BoardAnimation(pictures, width, height, ExportSettingsRules.parseInterval(settings.intervalText), share -> {
                    if (!disposed)
                        downloadButton.text = progressLabel(share);
                }, onExported);
        }
    }

    private function onExported(blob:Null<Blob>):Void
    {
        animation = null;

        if (disposed)
            return;

        if (blob != null)
            FileDownload.save(blob, fileName);
        setBusy(false);
    }

    private function setBusy(value:Bool):Void
    {
        busy = value;
        refresh();
    }

    private function downloadLabel():String
    {
        return LocaleUtils.localeBinding(settings.kind == Image ? "intellector.overlay.share.download.image" : "intellector.overlay.share.download.animation");
    }

    private static function progressLabel(share:Float):String
    {
        return LocaleUtils.localeBinding("intellector.overlay.share.generating", Std.string(Math.floor(share * 100)));
    }
}
