package gfx.common;

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
        turnColorLabel.customStyle = {fontSize: width / 10.5};
    }

    public function setSituation(sit:Situation)
    {
        board.setShownSituation(sit);
        turnColorLabel.text = Dictionary.getPhrase(TURN_COLOR(sit.turnColor));
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

        if (situation != null)
            situation = Situation.starting();

        board = new Board(situation, orientationColor, 40, None);

        var boardWrapper:BoardWrapper = new BoardWrapper(board);
        boardWrapper.percentWidth = 100;
        boardWrapper.maxPercentHeight = 100;
        
        boardContainer.addComponent(boardWrapper);
        onWidthChanged();
    }
}