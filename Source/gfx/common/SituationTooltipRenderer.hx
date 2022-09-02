package gfx.common;

import haxe.ui.styles.Style;
import struct.PieceColor;
import gfx.basic_components.BoardWrapper;
import dict.Dictionary;
import gameboard.Board;
import struct.Situation;
import haxe.ui.core.ItemRenderer;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/common/situation_tooltip_renderer.xml"))
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

        board = new Board(situation, orientationColor, 40, None);

        var boardWrapper:BoardWrapper = new BoardWrapper(board);
        boardWrapper.percentWidth = 100;
        boardWrapper.maxPercentHeight = 100;
        
        boardContainer.addComponent(boardWrapper);
        onWidthChanged();

        if (situation == null)
            setSituation(Situation.starting());
        else
            setSituation(situation);
    }
}