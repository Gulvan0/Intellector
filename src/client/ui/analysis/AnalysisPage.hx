package client.ui.analysis;

import client.datatypes.game.PlyNavigationType;
import client.datatypes.variations.PlyTreeChange;
import client.datatypes.variations.PlyTreeCursor;
import client.datatypes.variations.PlyTreeNode;
import client.datatypes.variations.PositionDraft;
import client.formatters.VariationFormatters;
import client.ui.BoardLayoutTier;
import client.ui.analysis.editor.EditorCard;
import client.ui.analysis.editor.EditorTool;
import client.ui.analysis.editor.EditorToolCard;
import client.ui.analysis.variations.VariationsCard;
import client.ui.common.board.EditIntent;
import client.ui.common.board.InteractiveBoard;
import client.ui.common.board.MoveRulesAdapter;
import client.ui.common.board.PositionChangeCause;
import client.ui.common.board.tools.AnalysisMovePolicy;
import client.ui.common.board.tools.EditorMovePolicy;
import client.ui.common.overlays.share.ShareOverlay;
import client.ui.game.MoveStrip;
import client.ui.game.MovesCard;
import haxe.ui.Toolkit;
import haxefolio.PageBase;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import morestd.Detachable;

/**
    The analysis board: moves played on it grow a tree of variations; the position editor replaces
    the tree with one starting from the edited position.
**/
class AnalysisPage extends PageBase
{
    // below them, the layout stops shrinking and the page scrolls instead
    private static inline final MIN_WIDE_HEIGHT:Float = 520;

    private final studyId:Null<Int>;

    private var cursor:PlyTreeCursor;
    // the node the board shows outside the editor
    private var shownNode:PlyTreeNode;
    private var draft:Null<PositionDraft> = null;
    private var expanded:Bool = false;

    private var board:InteractiveBoard;
    private var stage:AnalysisStage;
    private var analysisLayout:AnalysisLayout;
    private var variationsCard:VariationsCard;
    private var movesCard:MovesCard;
    private var moveStrip:MoveStrip;
    private var actionsCard:AnalysisActionsCard;
    private var editorCard:EditorCard;
    private var toolCard:EditorToolCard;
    private var handles:Array<Detachable> = [];

    public function new(?studyId:Null<Int>)
    {
        super();
        this.studyId = studyId;
    }

    private override function init():Void
    {
        setTitle(GroupedLocaleResolvers.analysisTitle(studyId != null), studyId);
        addClass(StyleClass.GAME_PAGE);

        cursor = new PlyTreeCursor(Position.defaultStarting());
        shownNode = cursor.selected;

        board = new InteractiveBoard(shownNode.position, White, analysisPolicy());
        handles.push(board.playMove.subscribe(cursor.play));
        handles.push(board.editIntents.subscribe(onEdit));

        toolCard = new EditorToolCard(onToolChosen);
        stage = new AnalysisStage(board, toolCard);
        stage.onFitted = fitLayoutHeight; // compact: the variations card's minimum depends on the board's height
        variationsCard = new VariationsCard({
            onSelect: cursor.select,
            onDelete: cursor.deleteSelected,
            onExpandToggled: toggleExpanded
        });
        movesCard = new MovesCard(navigate);
        moveStrip = new MoveStrip(navigate, () -> analysisLayout.toggleMoves());
        actionsCard = new AnalysisActionsCard({
            onFlip: flip,
            onEditPosition: openEditor,
            onShare: share,
            onPlayFromHere: () -> {}
        });
        editorCard = new EditorCard({
            onSideChosen: color -> editDraft(() -> draft.setTurnColor(color)),
            onImport: () -> {},
            onClear: () -> editDraft(() -> draft.clear()),
            onReset: () -> editDraft(() -> draft.reset()),
            onStarting: () -> editDraft(() -> draft.setStarting()),
            onApply: applyDraft,
            onDiscard: closeEditor
        });

        analysisLayout = new AnalysisLayout(variationsCard, stage, moveStrip, movesCard, actionsCard, editorCard, toolCard);
        addComponent(analysisLayout);
        handles.push(BoardLayoutTier.bind(tier -> {
            analysisLayout.setTier(tier);
            fitLayoutHeight();
        }));

        variationsCard.setMode(Preferences.variationView.get());
        handles.push(Preferences.variationView.onChange(variationsCard.setMode));
        handles.push(cursor.onChanged.subscribe(onCursorChanged));

        variationsCard.showTree(cursor.tree, cursor.selected);
        refreshMoves();
    }

    private override function onClose():Void
    {
        for (handle in handles)
            handle.detach();
        handles = [];
        board.dispose();
        stage.dispose();
    }

    private override function onResize(width:Float, height:Float):Void
    {
        fitLayoutHeight();
    }

    /*
        Pages flow in a scrolling area, so the layout takes the area's height explicitly: the area's
        visible height less the insets above the layout, mirrored below it.
    */
    private function fitLayoutHeight():Void
    {
        if (analysisLayout == null)
            return;

        if (!analysisLayout.fillsHeight())
        {
            stage.setMaxHeight(null);
            analysisLayout.height = null;
            analysisLayout.invalidateComponentLayout();
            return;
        }

        Toolkit.callLater(() -> {
            var scrollArea:Null<js.html.Element> = this.element.closest(".haxefolio-scroll-area");
            if (scrollArea == null || !analysisLayout.fillsHeight())
                return;

            var inset:Float = analysisLayout.element.getBoundingClientRect().top - scrollArea.getBoundingClientRect().top + scrollArea.scrollTop;
            var availableHeight:Float = Math.floor(scrollArea.clientHeight - 2 * inset);
            var minHeight:Float = MIN_WIDE_HEIGHT;
            if (analysisLayout.isCompact())
            {
                minHeight = analysisLayout.compactMinHeight();
                stage.setMaxHeight(Math.floor(analysisLayout.compactStageMaxHeight(availableHeight))); // the board shrinks for everything else to fit
            }
            else
                stage.setMaxHeight(null);
            var height:Float = Math.max(minHeight, availableHeight);
            if (analysisLayout.height != height)
                analysisLayout.height = height;
        });
    }

    private function analysisPolicy():AnalysisMovePolicy
    {
        return new AnalysisMovePolicy(MoveRulesAdapter.DEFAULT);
    }

    private function onCursorChanged(change:PlyTreeChange):Void
    {
        var selected:PlyTreeNode = cursor.selected;
        if (selected != shownNode)
        {
            var cause:PositionChangeCause = selected.parent == shownNode ? Move : Replacement;
            shownNode = selected;
            board.setPosition(selected.position, cause);
            board.setLastMove(selected.ply);
        }

        switch change
        {
            case Structure:
                variationsCard.showTree(cursor.tree, selected);
            case Selection:
                variationsCard.select(selected);
        }
        refreshMoves();
    }

    private function refreshMoves():Void
    {
        var line:Array<PlyTreeNode> = cursor.selectedLine();
        var selected:PlyTreeNode = cursor.selected;
        movesCard.setMoves(VariationFormatters.lineNotations(line), cursor.tree.root.position.turnColor);
        movesCard.setShown(selected.depth, line.length - 1);
        moveStrip.setShown(selected.depth, line.length - 1, VariationFormatters.notation(selected));
    }

    private function navigate(type:PlyNavigationType):Void
    {
        if (draft == null)
            cursor.navigate(type);
    }

    private function flip():Void
    {
        var orientation:PieceColor = board.getOrientation().opposite();
        board.setOrientation(orientation);
        toolCard.setOrientation(orientation);
    }

    private function share():Void
    {
        ShareOverlay.present({position: shownNode.position, orientation: board.getOrientation(), lastMove: shownNode.ply, game: null});
    }

    private function toggleExpanded():Void
    {
        if (draft != null)
            return;

        expanded = !expanded;
        analysisLayout.setExpanded(expanded);
        variationsCard.setExpanded(expanded);
    }

    private function openEditor():Void
    {
        if (draft != null)
            return;
        if (expanded)
            toggleExpanded();

        draft = new PositionDraft(shownNode.position);
        board.setPosition(draft.position, Replacement);
        board.setLastMove(null);
        board.setPolicy(new EditorMovePolicy());
        toolCard.select(FreeMove);
        onToolChosen(FreeMove);

        setLocked(true);
        analysisLayout.setEditing(true);
        fitLayoutHeight();
        refreshEditor();
    }

    private function closeEditor():Void
    {
        if (draft == null)
            return;

        draft = null;
        board.setEditMode(Moving);
        board.setPolicy(analysisPolicy());
        board.setPosition(shownNode.position, Replacement);
        board.setLastMove(shownNode.ply);
        setLocked(false);
        analysisLayout.setEditing(false);
        fitLayoutHeight();
    }

    // a changed position starts the analysis over from it; an unchanged one just closes the editor
    private function applyDraft():Void
    {
        if (draft == null || !draft.isValid())
            return;

        var changed:Bool = draft.isChanged();
        var position:Position = draft.position;
        closeEditor();
        if (changed)
            cursor.reset(position);
    }

    private function setLocked(locked:Bool):Void
    {
        variationsCard.setLocked(locked);
        movesCard.setLocked(locked);
        moveStrip.setLocked(locked);
    }

    private function onToolChosen(tool:EditorTool):Void
    {
        board.setEditMode(switch tool {
            case FreeMove: Moving;
            case Place(piece): Placing(piece);
            case DeletePiece: Clearing;
        });
    }

    private function onEdit(intent:EditIntent):Void
    {
        switch intent
        {
            case MovePiece(from, to):
                editDraft(() -> draft.movePiece(from, to));
            case PlacePiece(hex, piece):
                editDraft(() -> draft.placePiece(hex, piece));
            case ClearHex(hex):
                editDraft(() -> draft.clearHex(hex));
        }
    }

    private function editDraft(edit:Void->Void):Void
    {
        if (draft == null)
            return;

        edit();
        board.setPosition(draft.position, Replacement);
        refreshEditor();
    }

    private function refreshEditor():Void
    {
        editorCard.refresh(draft, cursor.tree.moveCount());
    }
}
