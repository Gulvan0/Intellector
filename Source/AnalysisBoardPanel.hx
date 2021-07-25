package;

import haxe.ui.styles.Style;
import haxe.Timer;
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
    private static var defaultScoreStyle:Style = {fontSize: 24};
    private var field:AnalysisField;
    private var scoreLabel:Label;

    private function onAnalyzePressed(color:PieceColor) 
    {
        scoreLabel.customStyle = defaultScoreStyle;
        scoreLabel.text = "...";

        Timer.delay(() -> {
            var situation:Situation = field.currentSituation.copy();
            situation.turnColor = color;
            var result = AlphaBeta.evaluate(situation, 6, color == White);
            var recommendedMove = result.plySequence[0];
                
            scoreLabel.text = result.score.toString();
            field.rmbSelectionBackToNormal();
            field.drawArrow(recommendedMove.from, recommendedMove.to);
        }, 20);
    }

    private function onClearPressed() 
    {
        scoreLabel.text = "";
        field.clearBoard();
    }

    private function onResetPressed() 
    {
        scoreLabel.text = "";
        field.reset();
    }

    public function deprecateScore() 
    {
        scoreLabel.customStyle = {fontSize: 24, color: 0xCCCCCC};
    }

    public function new(field:AnalysisField) 
    {
        super();
        this.field = field;

        var actionButtons:VBox = new VBox();

        actionButtons.addComponent(createBtn(ANALYSIS_CLEAR, 200, onClearPressed));
        actionButtons.addComponent(createBtn(ANALYSIS_RESET, 200, onResetPressed));

        var analysisBtns:HBox = new HBox();
        analysisBtns.addComponent(createBtn(ANALYSIS_ANALYZE_WHITE, 95, onAnalyzePressed.bind(White)));
        analysisBtns.addComponent(createBtn(ANALYSIS_ANALYZE_BLACK, 95, onAnalyzePressed.bind(Black)));
        actionButtons.addComponent(analysisBtns);

        scoreLabel = new Label();
        scoreLabel.customStyle = defaultScoreStyle;
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