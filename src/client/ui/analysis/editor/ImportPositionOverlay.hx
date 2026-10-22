package client.ui.analysis.editor;

import client.GroupedLocaleResolvers.importPositionOverlay as phrase;
import haxe.ui.Toolkit;
import haxefolio.HaxeFolioApp;
import haxefolio.appearance.AppearanceContext;
import haxefolio.appearance.GeometryTokens;
import haxefolio.overlay.OverlayContent;
import haxefolio.structure.ActionBar;
import haxefolio.structure.ActionButton;
import intellectorboard.position.Position;

/**
    Importing a position into the position editor from a SIP string. The primary action stays
    disabled in place until the input is a valid starting position.
**/
class ImportPositionOverlay
{
    /** `onImport` receives a valid starting position **/
    public static function present(onImport:Position->Void):Void
    {
        HaxeFolioApp.present("import-position", build.bind(onImport), null, {
            geometry: {
                dialogWidth: StyleVars.IMPORT_POSITION_OVERLAY_WIDTH,
                dialogHeight: dialogHeight(),
                headerHeight: StyleVars.IMPORT_POSITION_OVERLAY_HEADER_HEIGHT,
                actionBarHeight: StyleVars.IMPORT_POSITION_OVERLAY_FOOTER_HEIGHT
            }
        });
    }

    private static function build(onImport:Position->Void, dismiss:Void->Void):OverlayContent
    {
        var form:Null<ImportPositionForm> = null;
        var submitButton:Null<ActionButton> = null;

        function refresh():Void
        {
            if (form == null || submitButton == null)
                return;

            submitButton.enabled = form.importablePosition() != null;
        }

        function submit():Void
        {
            var position:Null<Position> = form.importablePosition();

            if (position == null)
                return;

            dismiss();
            onImport(position);
        }

        form = new ImportPositionForm(submit, refresh);

        var cancelButton:ActionButton = new ActionButton(phrase("cancel"), dismiss, false, null, StyleVars.IMPORT_POSITION_CANCEL_WIDTH_PERCENT);
        submitButton = new ActionButton(phrase("submit"), submit, true);
        refresh();

        // the frame is put on screen right after this factory returns
        Toolkit.callLater(form.focus);

        return {
            regions: [
                Header(phrase("title")),
                Scroll(form),
                Actions(new ActionBar([cancelButton, submitButton]))
            ],
            onDismissed: form.dispose
        };
    }

    private static function dialogHeight():Int
    {
        var geometry:GeometryTokens =AppearanceContext.current.geometry;
        var body:Int = ImportPositionForm.bodyHeight(geometry.messageLine, geometry.fieldHeight.resolve(false));

        return StyleVars.IMPORT_POSITION_OVERLAY_HEADER_HEIGHT + body + StyleVars.IMPORT_POSITION_OVERLAY_FOOTER_HEIGHT.resolve(false);
    }
}
