package client.ui.common.overlays.share;

import client.datatypes.share.ExportSettings;
import client.datatypes.share.SharedGame;
import client.datatypes.share.ShareSnapshot;
import client.formatters.PinFormatters;
import client.logic.share.ExportSettingsRules;
import client.ui.common.board.export.BoardRaster;
import client.ui.common.board.export.BoardRaster.BoardPicture;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.form.CopyField;

/** Share game: its link, its record as PIN, and an animation replaying it **/
class ShareGamePage extends SharePage
{
    /** `snapshot` must hold a game **/
    public function new(snapshot:ShareSnapshot, collapsed:Bool)
    {
        super();

        var game:SharedGame = snapshot.game;

        var linkField:CopyField = new CopyField(LocaleUtils.localeBinding("intellector.overlay.share.link"), HaxeFolioApp.pageUrl('live/${game.info.id}'), StyleVars.SHARE_COPY_BUTTON_WIDTH);
        addSection(linkField, linkField.dispose);

        var pin:String = PinFormatters.pin(game.info, game.plies, game.ending);
        var pinField:CopyField = new CopyField(LocaleUtils.localeBinding("intellector.overlay.share.pin"), pin, StyleVars.SHARE_COPY_BUTTON_WIDTH, StyleVars.SHARE_PIN_HEIGHT);
        pinField.addClass(StyleClass.SHARE_MONO);
        addSection(pinField, pinField.dispose);

        var width:Int = StyleVars.SHARE_DEFAULT_ANIMATION_WIDTH;
        var settings:ExportSettings = new ExportSettings(Animation, width, Math.round(width * BoardRaster.naturalRatio(true)), StyleVars.SHARE_DEFAULT_BACKGROUND, StyleVars.SHARE_DEFAULT_INTERVAL_MS);

        function frames(settings:ExportSettings):Array<BoardPicture>
        {
            return [for (i in 0...game.positions.length) {
                position: game.positions[i],
                orientation: snapshot.orientation,
                lastMove: i > 0 ? game.plies[i - 1] : null,
                labels: settings.labels,
                background: ExportSettingsRules.effectiveBackground(settings)
            }];
        }

        var panel:ExportPanel = new ExportPanel(settings, frames, 'intellector-game-${game.info.id}.gif', false, collapsed);
        addLabelledSection("intellector.overlay.share.section.animation", panel, panel.dispose);
    }
}
