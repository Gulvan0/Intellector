package client.ui.common.challenges;

import client.ui.Assets;
import client.ui.common.board.BoardGeometry;
import client.ui.common.board.BoardSurface;
import haxe.ui.containers.VBox;
import haxefolio.ElementShadow;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/challenges/position_preview_popover.xml"))
class PositionPreviewPopover extends VBox
{
    public final position:Position;

    /**
        The board is oriented for `orientation`. `title`, if given, is shown above the position, with
        a ✕ calling `onClose` if that's given too.
    **/
    public function new(position:Position, orientation:PieceColor, ?title:String, ?onClose:Void->Void)
    {
        super();

        this.position = position;

        ElementShadow.apply(element, StyleVars.CHALLENGE_PREVIEW_SHADOW);

        if (title != null)
        {
            titleRow.hidden = false;
            titleLabel.text = title;
        }

        if (onClose != null)
        {
            closeButton.hidden = false;
            closeButton.onClick = _ -> onClose();
        }

        sideToMoveIcon.resource = Assets.colorIcon(position.turnColor);

        sideToMoveLabel.text = GroupedLocaleResolvers.turnColor(position.turnColor);

        boardSlot.height = boardSlot.width * BoardGeometry.GRID_HEIGHT / BoardGeometry.GRID_WIDTH;

        var board:BoardSurface = new BoardSurface(position, orientation, NONE);
        boardSlot.addComponent(board);
    }
}
