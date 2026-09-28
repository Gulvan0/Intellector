package client.ui.analysis;

import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import client.ui.common.board.BoardSurface;
import client.ui.common.board.BoardCoordinatesMode;
import client.ui.common.board.BoardCoordinatesMode.BoardCoordinatesModeExtension;

class AnalysisPage extends PageBase
{
    private final studyId:Null<Int>;

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
            replaces this with a real position editor driving a single board.
        */
        var startingPosition:Position = Position.defaultStarting();
        var mode:BoardCoordinatesMode = BoardCoordinatesModeExtension.fromPreferenceValue(Preferences.boardCoordinates.get());

        var mainBoard:BoardSurface = new BoardSurface(startingPosition, White, mode);
        content.addComponent(mainBoard);

        var previewRow:HBox = new HBox();
        previewRow.percentWidth = 100;
        content.addComponent(previewRow);

        var previewModes:Array<BoardCoordinatesMode> = [None, FilesOnly, All];
        var previewOrientations:Array<PieceColor> = [White, Black, White];

        for (i in 0...previewModes.length)
        {
            var previewWrapper:VBox = new VBox();
            previewWrapper.width = 150;

            var preview:BoardSurface = new BoardSurface(startingPosition, previewOrientations[i], previewModes[i]);
            previewWrapper.addComponent(preview);
            previewRow.addComponent(previewWrapper);
        }
    }
}
