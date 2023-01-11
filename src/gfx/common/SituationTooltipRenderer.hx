package gfx.common;

import haxe.ui.styles.Style;
import net.shared.PieceColor;
import dict.Dictionary;
import gameboard.Board;
import haxe.ui.core.ItemRenderer;
import net.shared.board.Situation;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/common/situation_tooltip_renderer.xml"))
class SituationTooltipRenderer extends ItemRenderer
{
    private var board:Board;

    private function onWidthChanged()
    {
        var newStyle:Style = turnColorLabel.customStyle.clone();
        newStyle.fontSize = width / 10.5;
        turnColorLabel.customStyle = newStyle;
    }

    public function setSituation(sit:Situation)
    {
        board.setShownSituation(sit);
        turnColorLabel.text = Dictionary.getPhrase(TURN_COLOR(sit.turnColor));
        turnColorLabel.invalidateComponent();
        turnColorLabel.validateNow();
    }

    public function setOrientation(orientationColor:PieceColor)
    {
        board.setOrientation(orientationColor);
    }

    /*private override function onDataChanged(data:Dynamic)
    {
        setSituation(data);
    }*/

    public function new(?situation:Situation, ?orientationColor:PieceColor)
    {
        super();

        board = new Board(situation, orientationColor, None);
        board.percentWidth = 100;
        board.percentHeight = 100;
        boardContainer.addComponent(board);
        
        onWidthChanged();

        if (situation == null)
            setSituation(Situation.defaultStarting());
        else
            setSituation(situation);
    }
}