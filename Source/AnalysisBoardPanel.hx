package;

import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import analysis.AlphaBeta;
import struct.Situation;
import gameboards.AnalysisField;
import struct.PieceColor;
import haxe.ui.components.Label;
import dict.Dictionary;
import haxe.ui.components.Button;
import dict.Phrase;
import openfl.display.Sprite;

class AnalysisBoardPanel extends Sprite
{
    private var field:AnalysisField;
    private var scoreLabel:Label;

    private function onAnalyzePressed(color:PieceColor) 
    {
        scoreLabel.text = "...";

        var situation:Situation = field.currentSituation.copy();
        situation.turnColor = color;
        var result = AlphaBeta.evaluate(situation, 6, color == White);
        var recommendedMove = result.plySequence[0];
            
        scoreLabel.text = result.score.toString();
        field.rmbSelectionBackToNormal();
        field.drawArrow(recommendedMove.from, recommendedMove.to);
    }

    public function new(field:AnalysisField) 
    {
        super();
        this.field = field;

        var actionButtons:VBox = new VBox();

        actionButtons.addComponent(createBtn(ANALYSIS_CLEAR, 200, field.clearBoard));
        actionButtons.addComponent(createBtn(ANALYSIS_RESET, 200, field.reset));

        var analysisBtns:HBox = new HBox();
        analysisBtns.addComponent(createBtn(ANALYSIS_ANALYZE_WHITE, 95, onAnalyzePressed.bind(White)));
        analysisBtns.addComponent(createBtn(ANALYSIS_ANALYZE_BLACK, 95, onAnalyzePressed.bind(Black)));
        actionButtons.addComponent(analysisBtns);

        scoreLabel = new Label();
        scoreLabel.customStyle = {fontSize: 24};
        scoreLabel.width = 200;
        scoreLabel.textAlign = "center";
        actionButtons.addComponent(scoreLabel);

        addChild(actionButtons);
    }

    private function createBtn(phrase:Phrase, width:Float, callback:Void->Void):Button
    {
        var btn = new Button();
        btn.width = width;
        btn.text = Dictionary.getPhrase(phrase);

        btn.onClick = (e) -> {
            callback();
        }

        return btn;
    }
}