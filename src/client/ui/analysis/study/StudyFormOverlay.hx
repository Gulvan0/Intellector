package client.ui.analysis.study;

import client.datatypes.study.Study;
import client.datatypes.study.StudyDetails;
import client.datatypes.variations.PlyTreeNode;
import client.ui.analysis.study.StudyPreviewPanel.PreviewKind;
import client.ui.analysis.study.StudyPreviewPanel.PreviewSource;
import haxe.ui.Toolkit;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.ByWidth;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.appearance.PartialGeometryTokens;
import haxefolio.overlay.OverlayContent;
import intellectorboard.primitives.piece.PieceColor;

/** What the create overlay's card preview chooses from **/
typedef StudyPreviewOptions =
{
    /** The marked node, or the main line's end while none is **/
    node:PlyTreeNode,
    kind:PreviewKind,
    selected:PlyTreeNode,
    orientation:PieceColor
}

/**
    The details of a study as a form. Creating, the form opens prefilled and sits beside the card
    preview; editing, it holds the study's details and the footer offers Delete study too. A request
    keeps the overlay open and its primary action disabled until it ends: done, the overlay closes;
    failed, the footer says so and everything stays as typed.
**/
class StudyFormOverlay
{
    /** `create` sends the request and calls its last argument with whether it succeeded **/
    public static function presentCreate(initial:StudyDetails, preview:StudyPreviewOptions, create:StudyDetails->PreviewSource->(Bool->Void)->Void):Void
    {
        HaxeFolioApp.present(
            "study-create",
            buildCreate.bind(initial, preview, create, false),
            buildCreate.bind(initial, preview, create, true),
            {geometry: geometry(StyleVars.STUDY_CREATE_OVERLAY_WIDTH)}
        );
    }

    /** `save` and `remove` send their requests and call their last argument with whether they succeeded **/
    public static function presentEdit(study:Study, save:StudyDetails->(Bool->Void)->Void, remove:(Bool->Void)->Void):Void
    {
        HaxeFolioApp.present(
            "study-edit",
            buildEdit.bind(study, save, remove, false),
            buildEdit.bind(study, save, remove, true),
            {geometry: geometry(StyleVars.STUDY_EDIT_OVERLAY_WIDTH)}
        );
    }

    private static function buildCreate(initial:StudyDetails, preview:StudyPreviewOptions, create:StudyDetails->PreviewSource->(Bool->Void)->Void, collapsed:Bool, dismiss:Void->Void):OverlayContent
    {
        var form:Null<StudyForm> = null;
        var footer:Null<StudyFormFooter> = null;
        var panel:StudyPreviewPanel = new StudyPreviewPanel(preview.node, preview.kind, preview.selected, preview.orientation, StyleVars.STUDY_PREVIEW_BOARD_WIDTH);
        var busy:Bool = false;
        var dismissed:Bool = false;

        function submit():Void
        {
            var details:Null<StudyDetails> = form.details();
            if (details == null)
            {
                form.revealErrors();
                return;
            }
            if (busy)
                return;

            busy = true;
            footer.setBusy(true);
            footer.setFailure(null);
            create(details, panel.chosen, succeeded -> {
                busy = false;
                if (dismissed)
                    return;
                footer.setBusy(false);
                if (succeeded)
                    dismiss();
                else
                    footer.setFailure("intellector.overlay.study.save_failed");
            });
        }

        footer = new StudyFormFooter("intellector.overlay.study.create", {onCancel: dismiss, onSubmit: submit}, collapsed);
        form = new StudyForm(initial, () -> footer.setSubmittable(form.details() != null));
        footer.setSubmittable(form.details() != null);

        var body:Box = collapsed ? new VBox() : new HBox();
        body.percentWidth = 100;
        body.addClass(StyleClass.STUDY_FORM_BODY);
        body.addComponent(form);
        if (!collapsed)
            panel.width = StyleVars.STUDY_PREVIEW_PANEL_WIDTH;
        body.addComponent(panel);

        Toolkit.callLater(form.focus); // the frame is put on screen right after this factory returns

        return content("intellector.overlay.study.title.create", body, footer, collapsed, false, () -> {
            dismissed = true;
            form.dispose();
        });
    }

    private static function buildEdit(study:Study, save:StudyDetails->(Bool->Void)->Void, remove:(Bool->Void)->Void, collapsed:Bool, dismiss:Void->Void):OverlayContent
    {
        var form:Null<StudyForm> = null;
        var footer:Null<StudyFormFooter> = null;
        var busy:Bool = false;
        var dismissed:Bool = false;

        function finish(failureKey:String):Bool->Void
        {
            return succeeded -> {
                busy = false;
                if (dismissed)
                    return;
                footer.setBusy(false);
                if (succeeded)
                    dismiss();
                else
                    footer.setFailure(failureKey);
            };
        }

        function submit():Void
        {
            var details:Null<StudyDetails> = form.details();
            if (details == null)
            {
                form.revealErrors();
                return;
            }
            if (busy)
                return;

            busy = true;
            footer.setBusy(true);
            footer.setFailure(null);
            save(details, finish("intellector.overlay.study.save_failed"));
        }

        function confirmDelete():Void
        {
            if (busy)
                return;

            busy = true;
            footer.setBusy(true);
            remove(finish("intellector.overlay.study.delete_failed"));
        }

        footer = new StudyFormFooter("intellector.overlay.study.save", {onCancel: dismiss, onSubmit: submit, onDelete: confirmDelete}, collapsed);
        form = new StudyForm(study.details, () -> footer.setSubmittable(form.details() != null));
        footer.setSubmittable(form.details() != null);

        var body:VBox = new VBox();
        body.percentWidth = 100;
        body.addClass(StyleClass.STUDY_FORM_BODY);
        body.addComponent(form);

        return content("intellector.overlay.study.title.edit", body, footer, collapsed, true, () -> {
            dismissed = true;
            form.dispose();
        });
    }

    private static function content(titleKey:String, body:Component, footer:StudyFormFooter, collapsed:Bool, deletable:Bool, onDismissed:Void->Void):OverlayContent
    {
        var footerHeight:Int = if (!collapsed)
            StyleVars.STUDY_FORM_FOOTER_HEIGHT
        else if (deletable)
            StyleVars.STUDY_FORM_FOOTER_COLLAPSED_DELETABLE_HEIGHT
        else
            StyleVars.STUDY_FORM_FOOTER_COLLAPSED_HEIGHT;
        var footerRegionHeight:ByWidth<Int> = {expanded: footerHeight, collapsed: footerHeight};

        return {
            regions: [
                Header(LocaleUtils.localeBinding(titleKey)),
                Scroll(body),
                Custom(footerRegionHeight, footer)
            ],
            onDismissed: onDismissed
        };
    }

    private static function geometry(dialogWidth:Int):PartialGeometryTokens
    {
        return {
            dialogWidth: dialogWidth,
            dialogHeight: StyleVars.STUDY_FORM_OVERLAY_HEIGHT,
            headerHeight: StyleVars.STUDY_OVERLAY_HEADER_HEIGHT
        };
    }
}
