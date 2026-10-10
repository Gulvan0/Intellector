package client.ui.common.challenges;

import client.datatypes.ChallengeAcceptorColor;
import client.ui.Assets;
import client.ui.common.board.BoardGeometry;
import client.ui.common.board.BoardSurface;
import haxe.ui.containers.VBox;
import haxefolio.ElementShadow;
import intellectorboard.position.Position;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/challenges/position_preview_popover.xml"))
class PositionPreviewPopover extends VBox
{
    /**
        `ownColor` is the colour the user plays: the board is oriented for it. `title`, if given, is
        shown above the position, with a ✕ calling `onClose` if that's given too.
    **/
    public function new(position:Position, ownColor:ChallengeAcceptorColor, ?title:String, ?onClose:Void->Void)
    {
        super();

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

        sideToMoveIcon.resource = Assets.colorIcon(ownColor.getColor());

        sideToMoveLabel.text = GroupedLocaleResolvers.turnColor(position.turnColor);

        boardSlot.height = boardSlot.width * BoardGeometry.GRID_HEIGHT / BoardGeometry.GRID_WIDTH;

        var board:BoardSurface = new BoardSurface(position, ownColor.getColor() ?? White, NONE);
        boardSlot.addComponent(board);
    }
}
