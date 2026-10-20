package client.ui.common.overlays.share;

import client.datatypes.share.ShareSnapshot;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.appearance.AppearanceContext;
import haxefolio.overlay.OverlayContent;
import haxefolio.structure.Region;
import haxefolio.structure.TabPage;

/** One tab of the share overlay **/
typedef ShareGroup = {
    labelKey:String,
    /** Whether the group applies to what is shared **/
    available:ShareSnapshot->Bool,
    /** The page's height, its controls `fieldHeight` tall **/
    pageHeight:Int->Int,
    build:(snapshot:ShareSnapshot, collapsed:Bool) -> SharePage
}

/**
    Sharing and exporting what a page shows, as of the moment it opens: one tab per group that
    applies, the tab strip left out when only one does. The frame fits the tallest page, so it
    keeps its height between tabs.
**/
class ShareOverlay
{
    private static final GROUPS:Array<ShareGroup> = [
        {
            labelKey: "intellector.overlay.share.tab.position",
            available: _ -> true,
            pageHeight: ShareLayout.positionPageHeight,
            build: (snapshot, collapsed) -> new SharePositionPage(snapshot, collapsed)
        },
        {
            labelKey: "intellector.overlay.share.tab.game",
            available: snapshot -> snapshot.game != null,
            pageHeight: ShareLayout.gamePageHeight,
            build: (snapshot, collapsed) -> new ShareGamePage(snapshot, collapsed)
        }
    ];

    public static function present(snapshot:ShareSnapshot):Void
    {
        var groups:Array<ShareGroup> = GROUPS.filter(group -> group.available(snapshot));

        HaxeFolioApp.present("share", build.bind(snapshot, groups, false), build.bind(snapshot, groups, true), {
            geometry: {
                dialogWidth: StyleVars.SHARE_OVERLAY_WIDTH,
                dialogHeight: dialogHeight(groups),
                headerHeight: StyleVars.SHARE_OVERLAY_HEADER_HEIGHT
            }
        });
    }

    private static function build(snapshot:ShareSnapshot, groups:Array<ShareGroup>, collapsed:Bool, dismiss:Void->Void):OverlayContent
    {
        var pages:Array<SharePage> = groups.map(group -> group.build(snapshot, collapsed));
        var header:Region = Header(LocaleUtils.localeBinding("intellector.overlay.share.title"));

        var regions:Array<Region> = if (pages.length == 1)
            [header, Scroll(pages[0])];
        else
        {
            var tabPages:Array<TabPage> = [for (i in 0...pages.length) {label: LocaleUtils.localeBinding(groups[i].labelKey), content: pages[i]}];
            [header, Tabs(Choose, tabPages)];
        }

        return {
            regions: regions,
            onDismissed: () -> {
                for (page in pages)
                    page.dispose();
            }
        };
    }

    private static function dialogHeight(groups:Array<ShareGroup>):Int
    {
        var fieldHeight:Int = AppearanceContext.current.geometry.fieldHeight.resolve(false);
        var tallestPage:Int = 0;
        for (group in groups)
            tallestPage = Std.int(Math.max(tallestPage, group.pageHeight(fieldHeight)));

        var tabStrip:Int = groups.length > 1 ? AppearanceContext.current.geometry.tabStripHeight.resolve(false) : 0;

        return StyleVars.SHARE_OVERLAY_HEADER_HEIGHT + tabStrip + tallestPage;
    }
}
