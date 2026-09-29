package client.ui.analysis;

import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;
import morestd.Detachable;
import intellectorboard.plyapplication.PlyPerformer;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;
import client.datatypes.BoardCoordinatesMode;
import client.ui.common.board.BoardSurface;
import client.ui.common.board.MoveInteractionController;
import client.ui.common.board.MoveRulesAdapter;

class AnalysisPage extends PageBase
{
    private final studyId:Null<Int>;
    private var moveInteraction:MoveInteractionController;
    private var coordinatesModeHandle:Detachable;

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
            Interim smoke test for BoardSurface/MoveInteractionController (local hot-seat play,
            no session/network layer) until PositionEditorController (board_deferred.md item 3)
            replaces this with a real position editor.
        */
        var currentPosition:Position = Position.defaultStarting();

        // Live board - not a fixed preview mode, so it tracks the preference for as long as it's shown.
        var mainBoard:BoardSurface = new BoardSurface(currentPosition, White, Preferences.boardCoordinates.get());
        content.addComponent(mainBoard);
        coordinatesModeHandle = Preferences.boardCoordinates.onChange(mainBoard.setCoordinatesMode);

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

        var previewModes:Array<BoardCoordinatesMode> = [NONE, FILES_ONLY, ALL];
        var previewOrientations:Array<PieceColor> = [White, Black, White];

        for (i in 0...previewModes.length)
        {
            var previewWrapper:VBox = new VBox();
            previewWrapper.width = 150;

            // Separate Position - previews stay at the starting position regardless of mainBoard's game.
            // Fixed coordinates mode by design (demo of all three modes) - must not track the live preference.
            var preview:BoardSurface = new BoardSurface(Position.defaultStarting(), previewOrientations[i], previewModes[i]);
            previewWrapper.addComponent(preview);
            previewRow.addComponent(previewWrapper);
        }
    }

    private override function onClose():Void
    {
        moveInteraction.dispose();
        coordinatesModeHandle.detach();
    }
}
