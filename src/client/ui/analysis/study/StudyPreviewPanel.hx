package client.ui.analysis.study;

import client.datatypes.variations.PlyTreeNode;
import client.formatters.VariationFormatters;
import client.ui.common.board.BoardPreview;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.form.plumbing.FieldHeader;
import intellectorboard.primitives.piece.PieceColor;

using client.ui.ComponentExtension;

/** Where the preview of a study being saved comes from **/
enum PreviewSource
{
    /** The marked node, or the main line's end while none is **/
    Preview(node:PlyTreeNode, kind:PreviewKind);
    /** The node selected on the board **/
    Selection(node:PlyTreeNode);
}

enum PreviewKind
{
    Marked;
    LineEnd;
    AuthorsPick;
}

/**
    The card preview of the study being created: the preview as it stands, or the move selected on
    the board, its board and what it is. The selection can't be picked when it already is the preview.
**/
class StudyPreviewPanel extends VBox
{
    private final previewOption:Box;
    private final selectionOption:Box;
    private final board:BoardPreview;
    private final moveLabel:Label;
    private final descriptionLabel:Label;

    private final preview:PreviewSource;
    private final selection:PreviewSource;
    private final selectionIsPreview:Bool;

    public var chosen(default, null):PreviewSource;

    public function new(previewNode:PlyTreeNode, kind:PreviewKind, selected:PlyTreeNode, orientation:PieceColor, boardWidth:Float)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.STUDY_PREVIEW_PANEL);

        preview = Preview(previewNode, kind);
        selection = Selection(selected);
        selectionIsPreview = selected == previewNode;

        var header:FieldHeader = new FieldHeader(LocaleUtils.localeBinding("intellector.overlay.study.preview"));
        addComponent(header);

        var track:HBox = new HBox();
        track.percentWidth = 100;
        track.addClass(StyleClass.GAME_SEGMENTS);
        track.addClass(StyleClass.STUDY_PREVIEW_CHOICE);
        addComponent(track);

        previewOption = new Box(); // an HBox would ignore its content's horizontalAlign
        previewOption.percentWidth = 50;
        previewOption.addClass(StyleClass.GAME_SEGMENT);
        previewOption.onClick = _ -> choose(preview);
        previewOption.trackHover();
        var previewIcon:Image = new Image();
        previewIcon.resource = Assets.analysisIcon("card_preview");
        previewIcon.verticalAlign = "center";
        var previewCaption:Label = new Label();
        previewCaption.text = LocaleUtils.localeBinding('intellector.overlay.study.preview.${kindSlug(kind)}');
        previewCaption.verticalAlign = "center";
        var previewContent:HBox = new HBox();
        previewContent.addClass(StyleClass.GAME_SEGMENT_CONTENT);
        previewContent.horizontalAlign = "center";
        previewContent.verticalAlign = "center";
        previewContent.addComponent(previewIcon);
        previewContent.addComponent(previewCaption);
        previewOption.addComponent(previewContent);
        track.addComponent(previewOption);

        selectionOption = new Box();
        selectionOption.percentWidth = 50;
        selectionOption.addClass(StyleClass.GAME_SEGMENT);
        selectionOption.disabled = selectionIsPreview;
        selectionOption.onClick = _ -> {
            if (!selectionIsPreview)
                choose(selection);
        };
        selectionOption.trackHover();
        var selectionCaption:Label = new Label();
        selectionCaption.text = LocaleUtils.localeBinding("intellector.overlay.study.preview.current");
        selectionCaption.horizontalAlign = "center";
        selectionCaption.verticalAlign = "center";
        selectionOption.addComponent(selectionCaption);
        track.addComponent(selectionOption);

        var boardFrame:Box = new Box();
        boardFrame.percentWidth = 100;
        boardFrame.addClass(StyleClass.STUDY_PREVIEW_BOARD);
        addComponent(boardFrame);
        board = new BoardPreview(previewNode.position, orientation, boardWidth);
        board.horizontalAlign = "center";
        boardFrame.addComponent(board);

        var caption:VBox = new VBox();
        caption.percentWidth = 100;
        caption.addClass(StyleClass.GAME_TIGHT_STACK);
        addComponent(caption);

        moveLabel = new Label();
        moveLabel.addClass(StyleClass.STUDY_PREVIEW_MOVE);
        caption.addComponent(moveLabel);

        descriptionLabel = new Label();
        descriptionLabel.percentWidth = 100;
        descriptionLabel.addClass(StyleClass.GAME_HINT);
        caption.addComponent(descriptionLabel);

        var noteLabel:Label = new Label();
        noteLabel.percentWidth = 100;
        noteLabel.addClass(StyleClass.GAME_HINT);
        var noteKey:String = "intellector.overlay.study.preview.note";
        if (selectionIsPreview)
            noteKey = "intellector.overlay.study.preview.note_selected";
        else if (kind == AuthorsPick)
            noteKey = "intellector.overlay.study.preview.note_visitor";
        noteLabel.text = LocaleUtils.localeBinding(noteKey);
        addComponent(noteLabel);

        choose(preview);
    }

    private function choose(source:PreviewSource):Void
    {
        chosen = source;
        var choseSelection:Bool = source.match(Selection(_));
        previewOption.setClass(StyleClass.GAME_SEGMENT_ON, !choseSelection);
        selectionOption.setClass(StyleClass.GAME_SEGMENT_ON, choseSelection);

        var node:PlyTreeNode = switch source {
            case Preview(node, _): node;
            case Selection(node): node;
        }
        board.setPosition(node.position);
        moveLabel.text = node.isRoot() ? LocaleUtils.localeBinding("intellector.overlay.study.preview.start") : '${node.depth}. ${VariationFormatters.notation(node)}';
        descriptionLabel.text = LocaleUtils.localeBinding(switch source {
            case Preview(_, kind): 'intellector.overlay.study.preview.description.${kindSlug(kind)}';
            case Selection(_): "intellector.overlay.study.preview.description.current";
        });
    }

    private static function kindSlug(kind:PreviewKind):String
    {
        return switch kind {
            case Marked: "marked";
            case LineEnd: "line_end";
            case AuthorsPick: "authors_pick";
        }
    }
}
