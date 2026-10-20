package client.ui.common.overlays.share;

import client.datatypes.share.ExportSettings;
import client.datatypes.share.ShareSnapshot;
import client.logic.share.ExportSettingsRules;
import client.ui.common.board.export.BoardRaster;
import client.ui.common.board.export.BoardRaster.BoardPicture;
import haxefolio.LocaleUtils;
import haxefolio.form.CopyField;
import intellectorboard.mappers.Sip;

/** Share position: the shown position as SIP, and as an image **/
class SharePositionPage extends SharePage
{
    private static inline final FILE_NAME:String = "intellector-position.png";

    public function new(snapshot:ShareSnapshot, collapsed:Bool)
    {
        super();

        var sipField:CopyField = new CopyField(LocaleUtils.localeBinding("intellector.overlay.share.sip"), Sip.fromPosition(snapshot.position), StyleVars.SHARE_COPY_BUTTON_WIDTH);
        sipField.addClass(StyleClass.SHARE_MONO);
        addSection(sipField, sipField.dispose);

        var width:Int = StyleVars.SHARE_DEFAULT_IMAGE_WIDTH;
        var settings:ExportSettings = new ExportSettings(Image, width, Math.round(width * BoardRaster.naturalRatio(true)), StyleVars.SHARE_DEFAULT_BACKGROUND, StyleVars.SHARE_DEFAULT_INTERVAL_MS);

        function picture(settings:ExportSettings):Array<BoardPicture>
        {
            return [{
                position: snapshot.position,
                orientation: snapshot.orientation,
                lastMove: settings.highlightLastMove ? snapshot.lastMove : null,
                labels: settings.labels,
                background: ExportSettingsRules.effectiveBackground(settings)
            }];
        }

        var panel:ExportPanel = new ExportPanel(settings, picture, FILE_NAME, snapshot.lastMove != null, collapsed);
        addLabelledSection("intellector.overlay.share.section.image", panel, panel.dispose);
    }
}
