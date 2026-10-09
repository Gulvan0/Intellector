package client.ui.common.notifications.challenges;

import client.datatypes.ChallengeAcceptorColor;
import client.ui.Assets;
import client.ui.common.board.BoardGeometry;
import client.ui.common.board.BoardSurface;
import haxe.ui.containers.VBox;
import haxefolio.ElementShadow;
import intellectorboard.position.Position;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/notifications/position_preview_popover.xml"))
class PositionPreviewPopover extends VBox
{
    public function new(position:Position, acceptorColor:ChallengeAcceptorColor)
    {
        super();

        ElementShadow.apply(element, StyleVars.CHALLENGE_PREVIEW_SHADOW);

        sideToMoveIcon.resource = Assets.colorIcon(acceptorColor.getColor());

        sideToMoveLabel.text = GroupedLocaleResolvers.turnColor(position.turnColor);

        boardSlot.height = boardSlot.width * BoardGeometry.GRID_HEIGHT / BoardGeometry.GRID_WIDTH;

        var board:BoardSurface = new BoardSurface(position, acceptorColor.getColor() ?? White, NONE);
        boardSlot.addComponent(board);
    }
}
