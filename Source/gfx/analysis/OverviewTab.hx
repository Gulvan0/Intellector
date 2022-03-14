package gfx.analysis;

import dict.Phrase;
import dict.Dictionary;
import haxe.ui.containers.HBox;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.styles.Style;
import gfx.utils.PlyScrollType;
import struct.PieceColor;
import gfx.common.MoveNavigator;
import gfx.analysis.RightPanel.RightPanelEvent;
import haxe.ui.containers.VBox;

enum OverviewTabEvent
{
    AnalyzePressed(color:PieceColor);
    ExportSIPRequested;
    ExportStudyRequested;
    ScrollBtnPressed(type:PlyScrollType);
    SetPositionPressed;
}

class OverviewTab extends VBox
{
    private static var defaultScoreStyle:Style = {fontSize: 24};

    public var navigator(default, null):MoveNavigator;
    private var scoreLabel:Label;

    private var eventHandler:OverviewTabEvent->Void;

    public function init(eventHandler:OverviewTabEvent->Void)
    {
        this.eventHandler = eventHandler;
    }

    /*public function displayAnalysisResults(result:EvaluationResult) 
    {
        scoreLabel.text = result.score.toString();
    }*/

    public function displayLoadingOnScoreLabel()
    {
        scoreLabel.customStyle = defaultScoreStyle;
        scoreLabel.text = "...";
    }

    public function clearAnalysisScore() 
    {
        scoreLabel.text = "-";
    }

    public function deprecateScore() 
    {
        scoreLabel.customStyle = {fontSize: 24, color: 0xCCCCCC};
    }

    public function new()
    {
        super();

        //TODO: flip board btn, export as puzzle btn
        navigator = new MoveNavigator();
        navigator.init(m -> {eventHandler(ScrollBtnPressed(m));});
        navigator.horizontalAlign = 'center';

        var setPositionBtn:Button = createSimpleBtn(ANALYSIS_SET_POSITION, 300, SetPositionPressed);
        setPositionBtn.horizontalAlign = 'center';

        var exportSIPBtn:Button = createSimpleBtn(EXPORT_SIP_BTN_TOOLTIP, 300, ExportSIPRequested);
        exportSIPBtn.horizontalAlign = 'center';

        var exportStudyBtn:Button = createSimpleBtn(ANALYSIS_EXPORT_STUDY, 300, ExportStudyRequested);
        exportStudyBtn.horizontalAlign = 'center';

        var analyzeWhiteBtn = createSimpleBtn(ANALYSIS_ANALYZE_WHITE, 150, AnalyzePressed(White));
        analyzeWhiteBtn.disabled = true;
        var analyzeBlackBtn = createSimpleBtn(ANALYSIS_ANALYZE_BLACK, 150, AnalyzePressed(Black));
        analyzeBlackBtn.disabled = true;

        var analysisBtns:HBox = new HBox();
        analysisBtns.addComponent(analyzeWhiteBtn);
        analysisBtns.addComponent(analyzeBlackBtn);
        analysisBtns.horizontalAlign = 'center';

        scoreLabel = new Label();
        scoreLabel.customStyle = defaultScoreStyle;
        scoreLabel.text = "-";
        scoreLabel.width = 200;
        scoreLabel.textAlign = "center";
        scoreLabel.horizontalAlign = 'center';

        horizontalAlign = 'center';
        addComponent(navigator);
        addComponent(setPositionBtn);
        addComponent(exportSIPBtn);
        addComponent(exportStudyBtn);
        addComponent(analysisBtns);
        addComponent(scoreLabel);
    }

    private function createSimpleBtn(phrase:Phrase, width:Float, emittedEvent:OverviewTabEvent):Button
    {
        var btn = new Button();
        btn.width = width;
        btn.text = Dictionary.getPhrase(phrase);
        btn.onClick = e -> {
            eventHandler(emittedEvent);
        }
        return btn;
    }
}