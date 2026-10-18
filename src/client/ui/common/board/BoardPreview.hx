package client.ui.common.board;

import haxe.ui.containers.Box;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;

/** A static board `boardWidth` px wide, without coordinates, for a game or study in a list **/
class BoardPreview extends Box
{
    private final surface:BoardSurface;

    public function new(position:Position, orientation:PieceColor, boardWidth:Float)
    {
        super();
        width = boardWidth;
        height = boardWidth / BoardSurface.aspectRatioOf(NONE);
        verticalAlign = "center";

        surface = new BoardSurface(position, orientation, NONE);
        addComponent(surface);
    }

    public function setPosition(position:Position):Void
    {
        surface.setPosition(position, Replacement);
    }
}
