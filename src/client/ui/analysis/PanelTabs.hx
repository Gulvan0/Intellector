package client.ui.analysis;

import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

/** Variations | Moves: which of the two views of the ply tree the shared card shows **/
class PanelTabs extends Box
{
    private final variationsOption:Box;
    private final movesOption:Box;

    public function new(onMovesShownChosen:Bool->Void)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.ANALYSIS_PANEL_TABS);

        var track:HBox = new HBox();
        track.percentWidth = 100;
        track.addClass(StyleClass.GAME_SEGMENTS);
        addComponent(track);

        variationsOption = createOption("intellector.analysis.variations.title", () -> onMovesShownChosen(false));
        movesOption = createOption("intellector.live_game.moves.title", () -> onMovesShownChosen(true));
        track.addComponent(variationsOption);
        track.addComponent(movesOption);
        setMovesShown(false);
    }

    public function setMovesShown(movesShown:Bool):Void
    {
        variationsOption.setClass(StyleClass.GAME_SEGMENT_ON, !movesShown);
        movesOption.setClass(StyleClass.GAME_SEGMENT_ON, movesShown);
    }

    private function createOption(captionKey:String, onChosen:Void->Void):Box
    {
        var option:Box = new Box();
        option.percentWidth = 50;
        option.addClass(StyleClass.GAME_SEGMENT);
        option.onClick = _ -> onChosen();
        option.trackHover();

        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding(captionKey);
        label.horizontalAlign = "center";
        label.verticalAlign = "center";
        option.addComponent(label);
        return option;
    }
}
