package client.ui.analysis;

import client.ui.analysis.AnalysisPanel;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

/** Variations | Moves, plus Study while one is open: which panel the shared card shows **/
class PanelTabs extends Box
{
    private final options:Map<AnalysisPanel, Box> = [];
    private final studyOption:Box;

    public function new(onChosen:AnalysisPanel->Void)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.ANALYSIS_PANEL_TABS);

        var track:HBox = new HBox();
        track.percentWidth = 100;
        track.addClass(StyleClass.GAME_SEGMENTS);
        addComponent(track);

        var captionKeys:Map<AnalysisPanel, String> = [
            Variations => "intellector.analysis.variations.title",
            Moves => "intellector.live_game.moves.title",
            Study => "intellector.analysis.study.label"
        ];
        for (panel in [Variations, Moves, Study])
        {
            var option:Box = createOption(captionKeys.get(panel), () -> onChosen(panel));
            options.set(panel, option);
            track.addComponent(option);
        }
        studyOption = options.get(Study);
        setStudyShown(false);
        setShown(Variations);
    }

    public function setShown(shown:AnalysisPanel):Void
    {
        for (panel => option in options)
            option.setClass(StyleClass.GAME_SEGMENT_ON, panel == shown);
    }

    public function setStudyShown(shown:Bool):Void
    {
        studyOption.hidden = !shown;
        var percentWidth:Float = 100 / (shown ? 3 : 2);
        for (option in options)
            option.percentWidth = percentWidth;
    }

    private function createOption(captionKey:String, onChosen:Void->Void):Box
    {
        var option:Box = new Box();
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
