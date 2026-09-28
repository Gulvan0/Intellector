package client.ui.analysis;

import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;
import intellectorboard.plyapplication.PlyPerformer;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;
import client.ui.common.board.BoardSurface;
import client.ui.common.board.BoardCoordinatesMode;
import client.ui.common.board.BoardCoordinatesMode.BoardCoordinatesModeExtension;
import client.ui.common.board.MoveInteractionController;
import client.ui.common.board.MoveRulesAdapter;

class AnalysisPage extends PageBase
{
    private final studyId:Null<Int>;
    private var moveInteraction:MoveInteractionController;

    public function new(?studyId:Null<Int>)
    {
        super();
        this.studyId = studyId;
    }

    private override function init():Void
    {
        var titleKey:String = studyId != null
            ? LocaleUtils.localeBinding("intellector.analysis.study_title")
            : LocaleUtils.localeBinding("intellector.analysis.title");
        setTitle(titleKey, studyId);

        var content:VBox = new VBox();
        content.percentWidth = 100;
        addComponent(content);

        var label:Label = new Label();
        label.text = LocaleUtils.resolveText(titleKey, studyId);
        content.addComponent(label);

        /*
            Interim: exercises BoardSurface (knowledge/plans/board_plan.md) at a large size and
            several small (list-row-sized) previews, across orientations and all 3
            boardCoordinates modes, until PositionEditorController (board_deferred.md item 3)
            replaces this with a real position editor driving a single board. The main board is
            also wired to a live MoveInteractionController (board_deferred.md item 1, core click/
            drag pass only - no premove yet) for local hot-seat play, both colors moved from the
            same board with no session/network layer behind it.
        */
        var mode:BoardCoordinatesMode = BoardCoordinatesModeExtension.fromPreferenceValue(Preferences.boardCoordinates.get());
        var currentPosition:Position = Position.defaultStarting();

        var mainBoard:BoardSurface = new BoardSurface(currentPosition, White, mode);
        content.addComponent(mainBoard);

        moveInteraction = new MoveInteractionController(
            mainBoard,
            currentPosition,
            MoveRulesAdapter.DEFAULT,
            {allowedToMove: currentPosition.turnColor},
            (ply:RawPly) -> {
                PlyPerformer.performRawPly(currentPosition, ply);
                mainBoard.setPosition(currentPosition);
                moveInteraction.notifyPositionChanged(currentPosition);
                moveInteraction.notifyConfigChanged({allowedToMove: currentPosition.turnColor});
            }
        );

        var previewRow:HBox = new HBox();
        previewRow.percentWidth = 100;
        content.addComponent(previewRow);

        var previewModes:Array<BoardCoordinatesMode> = [None, FilesOnly, All];
        var previewOrientations:Array<PieceColor> = [White, Black, White];

        for (i in 0...previewModes.length)
        {
            var previewWrapper:VBox = new VBox();
            previewWrapper.width = 150;

            // A separate Position instance: the previews always show the starting position,
            // independent of whatever mainBoard's interactive game does to currentPosition.
            var preview:BoardSurface = new BoardSurface(Position.defaultStarting(), previewOrientations[i], previewModes[i]);
            previewWrapper.addComponent(preview);
            previewRow.addComponent(previewWrapper);
        }
    }

    private override function onClose():Void
    {
        moveInteraction.dispose();
    }
}
