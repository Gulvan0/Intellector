package client.ui.analysis.editor;

import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceData;
import intellectorboard.primitives.piece.PieceKind;

using client.ui.ComponentExtension;

/**
    The position editor's tools, under the board: a row of the far side's pieces then Free move,
    a row of the near side's pieces then Delete piece. Exactly one tool is selected.
**/
class EditorToolCard extends VBox
{
    private static final PIECE_ORDER:Array<PieceKind> = [Intellector, Dominator, Liberator, Aggressor, Defensor, Progressor];
    // the Intellector's art height; the rest are scaled as on the board
    private static inline final PIECE_ART_HEIGHT:Float = 36;
    private static inline final COMPACT_PIECE_ART_HEIGHT:Float = 26;

    /** With Free move and Delete piece labelled: six 48px piece tools, the 150px labelled one, 6px apart, 8px padding, 1px border **/
    public static inline final LABELLED_WIDTH:Float = 492;

    private final onToolChosen:EditorTool->Void;
    private final topRow:HBox;
    private final bottomRow:HBox;
    private final pieceTools:Map<PieceColor, Array<Box>> = [];
    private final freeMoveTool:Box;
    private final deletePieceTool:Box;
    private final wideLabels:Array<Label> = [];
    private final pieceArts:Array<{image:Image, kind:PieceKind}> = [];

    private var selected:EditorTool = FreeMove;
    private var nearColor:PieceColor = White;
    private var compact:Bool = false;
    private var narrow:Bool = false;

    public function new(onToolChosen:EditorTool->Void)
    {
        super();
        this.onToolChosen = onToolChosen;
        addClass(StyleClass.EDITOR_TOOL_CARD);

        topRow = new HBox();
        topRow.addClass(StyleClass.EDITOR_TOOL_ROW);
        bottomRow = new HBox();
        bottomRow.addClass(StyleClass.EDITOR_TOOL_ROW);
        addComponent(topRow);
        addComponent(bottomRow);

        for (color in [White, Black])
            pieceTools.set(color, [for (kind in PIECE_ORDER) createPieceTool(new PieceData(kind, color))]);

        freeMoveTool = createWideTool("free_move", "intellector.analysis.editor.free_move", FreeMove);
        deletePieceTool = createWideTool("delete_piece", "intellector.analysis.editor.delete_piece", DeletePiece);

        arrangeRows();
        refresh();
    }

    public function getSelected():EditorTool
    {
        return selected;
    }

    public function select(tool:EditorTool):Void
    {
        selected = tool;
        refresh();
    }

    /** The near side's pieces go to the bottom row **/
    public function setOrientation(nearColor:PieceColor):Void
    {
        this.nearColor = nearColor;
        arrangeRows();
    }

    /** Compact: Free move and Delete piece drop their words **/
    public function setCompact(compact:Bool):Void
    {
        this.compact = compact;
        for (art in pieceArts)
            sizePieceArt(art.image, art.kind, compact ? COMPACT_PIECE_ART_HEIGHT : PIECE_ART_HEIGHT);
        this.setClass(StyleClass.EDITOR_TOOL_CARD_COMPACT, compact);
        refreshLabels();
    }

    /** Narrower than `LABELLED_WIDTH` allows: Free move and Delete piece drop their words, so every tool fits **/
    public function setNarrow(narrow:Bool):Void
    {
        if (this.narrow == narrow)
            return;
        this.narrow = narrow;
        this.setClass(StyleClass.EDITOR_TOOL_CARD_NARROW, narrow);
        refreshLabels();
    }

    private function refreshLabels():Void
    {
        for (label in wideLabels)
            label.hidden = compact || narrow;
    }

    private function arrangeRows():Void
    {
        for (row in [topRow, bottomRow])
            for (child in row.childComponents.copy())
                row.removeComponent(child, false);

        for (tool in pieceTools.get(nearColor.opposite()))
            topRow.addComponent(tool);
        topRow.addComponent(freeMoveTool);
        for (tool in pieceTools.get(nearColor))
            bottomRow.addComponent(tool);
        bottomRow.addComponent(deletePieceTool);
    }

    private function choose(tool:EditorTool):Void
    {
        select(tool);
        onToolChosen(tool);
    }

    private function refresh():Void
    {
        for (color => tools in pieceTools)
            for (i in 0...tools.length)
                tools[i].setClass(StyleClass.EDITOR_TOOL_ON, isPlacing(new PieceData(PIECE_ORDER[i], color)));
        freeMoveTool.setClass(StyleClass.EDITOR_TOOL_ON, selected.match(FreeMove));
        deletePieceTool.setClass(StyleClass.EDITOR_TOOL_ON, selected.match(DeletePiece));
    }

    private function isPlacing(piece:PieceData):Bool
    {
        return switch selected {
            case Place(placed): placed.equals(piece);
            default: false;
        }
    }

    private function createPieceTool(piece:PieceData):Box
    {
        var tool:Box = new Box();
        tool.addClass(StyleClass.EDITOR_TOOL);
        LocaleManager.instance.registerComponent(tool, "tooltip", () -> {
            var pieceName:String = LocaleUtils.resolveText(LocaleUtils.localeBinding('intellector.piece.${piece.type.getName().toLowerCase()}.nominative'));
            return LocaleUtils.resolveText(LocaleUtils.localeBinding('intellector.analysis.editor.piece.${piece.color.getName().toLowerCase()}'), pieceName);
        });
        tool.onClick = _ -> choose(Place(piece));
        tool.trackHover();

        var image:Image = new Image();
        image.resource = Assets.pieceImage(piece.type, piece.color);
        sizePieceArt(image, piece.type, PIECE_ART_HEIGHT);
        image.horizontalAlign = "center";
        image.verticalAlign = "center";
        tool.addComponent(image);
        pieceArts.push({image: image, kind: piece.type});
        return tool;
    }

    private function sizePieceArt(image:Image, kind:PieceKind, intellectorHeight:Float):Void
    {
        image.height = Math.round(intellectorHeight * Assets.pieceRelativeScale(kind));
        image.width = Math.round(image.height * Assets.pieceAspectRatio(kind));
    }

    private function createWideTool(iconName:String, captionKey:String, tool:EditorTool):Box
    {
        var button:Box = new Box();
        button.addClass(StyleClass.EDITOR_TOOL);
        button.addClass(StyleClass.EDITOR_TOOL_WIDE);
        button.tooltip = LocaleUtils.localeBinding(captionKey);
        button.onClick = _ -> choose(tool);
        button.trackHover();

        var content:HBox = new HBox();
        content.addClass(StyleClass.EDITOR_TOOL_CONTENT);
        content.horizontalAlign = "center";
        content.verticalAlign = "center";
        button.addComponent(content);

        var icon:Image = new Image();
        icon.resource = Assets.analysisIcon(iconName);
        icon.verticalAlign = "center";
        content.addComponent(icon);

        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding(captionKey);
        label.verticalAlign = "center";
        wideLabels.push(label);
        content.addComponent(label);
        return button;
    }
}
