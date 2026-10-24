package client.ui.analysis.study;

import client.datatypes.study.Study;
import client.ui.analysis.study.StudyFooter.StudyActions;
import haxe.ui.containers.ContinuousHBox;
import haxe.ui.containers.VBox;
import haxefolio.ByWidth;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.overlay.OverlayContent;

/**
    Compact: the open study in full - visibility, name, author, dates, description, tags - over the
    save footer. Only the compact study bar opens it; the wider layouts show the same in a card.
**/
class StudySheetOverlay
{
    /**
        The footer stays the caller's to refresh while the sheet is open; `onDismissed` follows its
        closing. Save as new and Edit details act once the sheet is gone, as they open overlays of their own.
    **/
    public static function present(study:Study, own:Bool, actions:StudyActions, onDismissed:Void->Void):StudyFooter
    {
        var dismiss:Void->Void = () -> {};
        var afterDismissal:Null<Void->Void> = null;
        function dismissThen(action:Void->Void):Void
        {
            afterDismissal = action;
            dismiss();
        }
        var footer:StudyFooter = new StudyFooter({
            onSave: actions.onSave,
            onSaveAsNew: () -> dismissThen(actions.onSaveAsNew),
            onEditDetails: () -> dismissThen(actions.onEditDetails)
        });
        footer.addClass(StyleClass.STUDY_SHEET_FOOTER);
        var footerHeight:Int = own ? StyleVars.STUDY_SHEET_OWNER_FOOTER_HEIGHT : StyleVars.STUDY_SHEET_VISITOR_FOOTER_HEIGHT;

        var factory:(Void->Void)->OverlayContent = dismissOverlay -> {
            dismiss = dismissOverlay;
            return build(study, own, footer, footerHeight, dismissThen);
        };
        HaxeFolioApp.present("study", factory, null, {
            geometry: {
                dialogWidth: StyleVars.STUDY_SHEET_WIDTH,
                dialogHeight: StyleVars.STUDY_SHEET_HEIGHT,
                headerHeight: StyleVars.STUDY_OVERLAY_HEADER_HEIGHT
            }
        }, () -> {
            onDismissed();
            if (afterDismissal != null)
                afterDismissal();
        });
        return footer;
    }

    private static function build(study:Study, own:Bool, footer:StudyFooter, footerHeight:Int, dismissThen:(Void->Void)->Void):OverlayContent
    {
        var content:VBox = new VBox();
        content.percentWidth = 100;
        content.addClass(StyleClass.STUDY_SHEET_BODY);

        if (own)
        {
            var publicityBadge:StudyPublicityBadge = new StudyPublicityBadge();
            publicityBadge.setPublicity(study.details.publicity);
            content.addComponent(publicityBadge);
        }

        var info:StudyInfo = new StudyInfo();
        info.setStudy(study, own);
        content.addComponent(info);

        var tags:ContinuousHBox = new ContinuousHBox();
        tags.percentWidth = 100;
        tags.addClass(StyleClass.STUDY_SHEET_TAGS);
        for (button in StudyTagButtons.create(study, dismissThen))
            tags.addComponent(button);
        tags.hidden = study.details.tags.length == 0;
        content.addComponent(tags);

        var title:String = LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.overlay.study.title.sheet"), study.id);
        var footerRegionHeight:ByWidth<Int> = {expanded: footerHeight, collapsed: footerHeight};

        return {
            regions: [
                Header(title),
                Scroll(content),
                Custom(footerRegionHeight, footer)
            ]
        };
    }
}
