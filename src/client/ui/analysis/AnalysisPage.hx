package client.ui.analysis;

import client.logic.challenge.creation.ChallengePrefills;
import client.logic.variations.AnalysisStateCodec;
import client.logic.variations.AnalysisStateCodec.RestoredAnalysis;
import client.ui.common.overlays.challenge.ChallengeCreationLauncher;
import client.datatypes.game.PlyNavigationType;
import client.datatypes.study.Study;
import client.datatypes.variations.PlyTreeChange;
import client.datatypes.variations.PlyTreeCursor;
import client.datatypes.variations.PlyTreeNode;
import client.datatypes.variations.PositionDraft;
import client.formatters.VariationFormatters;
import client.logic.study.StudyContent;
import client.ui.BoardLayoutTier;
import client.ui.analysis.editor.EditorCard;
import client.ui.analysis.editor.EditorTool;
import client.ui.analysis.editor.EditorToolCard;
import client.ui.analysis.GameImport.ImportedGame;
import client.ui.analysis.editor.ImportPositionOverlay;
import client.ui.analysis.study.StudyMode;
import client.ui.analysis.study.StudyMode.StudyStatus;
import client.ui.analysis.variations.VariationsCard;
import client.ui.common.board.EditIntent;
import client.ui.common.board.InteractiveBoard;
import client.ui.common.board.MoveRulesAdapter;
import client.ui.common.board.PositionChangeCause;
import client.ui.common.board.tools.AnalysisMovePolicy;
import client.ui.common.board.tools.EditorMovePolicy;
import client.ui.common.board.tools.InertMovePolicy;
import client.ui.common.notifications.RequestFailureNotice;
import client.ui.common.overlays.share.ShareOverlay;
import client.ui.game.MoveStrip;
import client.ui.game.MovesCard;
import haxe.Timer;
import haxe.ui.Toolkit;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;
import js.Browser;
import http.HttpError;
import js.html.BeforeUnloadEvent;
import morestd.Detachable;

/** The game to analyze: its id and the number of plies to show; each null when the URL didn't hold a number **/
typedef AnalysisGameSeed =
{
    gameId:Null<Int>,
    plyCount:Null<Int>
}

/**
    The analysis board: moves played on it grow a tree of variations; the position editor replaces
    the tree with one starting from the edited position. Opened as a study, it shows the study's
    tree and lets its author save the edits; any board can be saved as a new study. One node may be
    marked as the study card's preview. Opened on a game, it shows the game's plies as one line and
    moves to the plain analysis path. Outside of a study, the tree, the selection and the mark
    are kept in the navigation state, so that a reload brings them back.
**/
class AnalysisPage extends PageBase
{
    // below them, the layout stops shrinking and the page scrolls instead
    private static inline final MIN_WIDE_HEIGHT:Float = 240;
    // above it, the wide layout keeps room under the board for the editor's tool card
    private static inline final ROOMY_WIDE_HEIGHT:Float = 560;

    private final studyId:Null<Int>;
    private final gameSeed:Null<AnalysisGameSeed>;
    private final gameImport:GameImport = new GameImport();

    private var cursor:PlyTreeCursor;
    // the node the board shows outside the editor
    private var shownNode:PlyTreeNode;
    private var draft:Null<PositionDraft> = null;
    private var expanded:Bool = false;
    // the card preview; the main line's end while null
    private var markedNode:Null<PlyTreeNode> = null;
    private var gameLoading:Bool = false;
    private var missingGameTimer:Null<Timer> = null;

    private var board:InteractiveBoard;
    private var stage:AnalysisStage;
    private var analysisLayout:AnalysisLayout;
    private var variationsCard:VariationsCard;
    private var movesCard:MovesCard;
    private var moveStrip:MoveStrip;
    private var actionsCard:AnalysisActionsCard;
    private var editorCard:EditorCard;
    private var toolCard:EditorToolCard;
    private var studyMode:StudyMode;
    private var handles:Array<Detachable> = [];

    public function new(?studyId:Null<Int>, ?gameSeed:AnalysisGameSeed)
    {
        super();
        this.studyId = studyId;
        this.gameSeed = gameSeed;
    }

    private override function init():Void
    {
        setTitle(GroupedLocaleResolvers.analysisTitle(studyId != null), studyId);
        addClass(StyleClass.GAME_PAGE);

        cursor = new PlyTreeCursor(Position.defaultStarting());
        restoreState();
        shownNode = cursor.selected;

        board = new InteractiveBoard(shownNode.position, White, analysisPolicy());
        handles.push(board.playMove.subscribe(play));
        handles.push(board.editIntents.subscribe(onEdit));

        toolCard = new EditorToolCard(onToolChosen);
        stage = new AnalysisStage(board, toolCard);
        stage.onFitted = fitLayoutHeight; // compact: the variations card's minimum depends on the board's height
        variationsCard = new VariationsCard({
            onSelect: cursor.select,
            onDelete: cursor.deleteSelected,
            onExpandToggled: toggleExpanded,
            onPreviewToggled: togglePreviewMark
        });
        movesCard = new MovesCard(navigate);
        moveStrip = new MoveStrip(navigate, () -> analysisLayout.toggleMoves());
        actionsCard = new AnalysisActionsCard({
            onFlip: flip,
            onEditPosition: openEditor,
            onShare: share,
            onPlayFromHere: playFromHere,
            onSaveAsStudy: () -> studyMode.saveAsNew()
        });
        editorCard = new EditorCard({
            onSideChosen: color -> editDraft(() -> draft.setTurnColor(color)),
            onImport: openImport,
            onClear: () -> editDraft(() -> draft.clear()),
            onReset: () -> editDraft(() -> draft.reset()),
            onStarting: () -> editDraft(() -> draft.setStarting()),
            onApply: applyDraft,
            onDiscard: closeEditor
        });

        studyMode = new StudyMode({
            cursor: cursor,
            getMarked: () -> markedNode,
            setMarked: setMarkedNode,
            getOrientation: board.getOrientation,
            onChanged: onStudyChanged
        });

        analysisLayout = new AnalysisLayout(variationsCard, stage, moveStrip, movesCard, actionsCard, editorCard, toolCard, studyMode.card, studyMode.bar);
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
        refreshCardPreview();

        Browser.window.addEventListener("beforeunload", onBeforeUnload);
        if (studyId != null)
            studyMode.open(studyId);
        else if (gameSeed != null)
            importGame();
    }

    private override function onClose():Void
    {
        Browser.window.removeEventListener("beforeunload", onBeforeUnload);
        for (handle in handles)
            handle.detach();
        handles = [];
        studyMode.dispose();
        gameImport.cancel();
        if (missingGameTimer != null)
            missingGameTimer.stop();
        board.dispose();
        stage.dispose();
    }

    private override function canLeave():Bool
    {
        return !studyMode.hasUnsavedChanges();
    }

    private function onBeforeUnload(event:BeforeUnloadEvent):Void
    {
        if (!studyMode.hasUnsavedChanges())
            return;

        event.preventDefault();
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
            analysisLayout.setRoomy(availableHeight >= ROOMY_WIDE_HEIGHT);
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

    private function isLoading():Bool
    {
        return gameLoading || studyMode.isLoading();
    }

    private function restoreState():Void
    {
        if (studyId != null || gameSeed != null)
            return;

        var restored:Null<RestoredAnalysis> = AnalysisStateCodec.decode(HaxeFolioApp.navigationState);
        if (restored == null)
            return;

        cursor.load(restored.tree);
        cursor.select(restored.selected);
        markedNode = restored.marked;
    }

    // a study is saved on the server, so only the bare board is kept in the navigation state
    private function persistState():Void
    {
        if (studyMode.isShown())
            HaxeFolioApp.setState(null);
        else
            HaxeFolioApp.setState(AnalysisStateCodec.encode(cursor.tree, cursor.selected, markedNode));
    }

    private function importGame():Void
    {
        gameLoading = true;
        refreshLock();

        if (gameSeed.gameId == null)
            missingGameTimer = Timer.delay(() -> finishImport(() -> RequestFailureNotice.show(LOAD_GAME, GameNotFound)), 0); // the page's URL is only set once it is built
        else
            gameImport.start(gameSeed.gameId, gameSeed.plyCount, onGameImported, onGameImportFailed);
    }

    private function onGameImported(game:ImportedGame):Void
    {
        finishImport(() -> {
            cursor.load(game.tree);
            cursor.select(game.selected);
        });
    }

    private function onGameImportFailed(error:Null<HttpError>):Void
    {
        finishImport(() -> {
            if (error == null)
                RequestFailureNotice.show(LOAD_GAME, NoConnection);
            else if (error.httpStatus == 404)
                RequestFailureNotice.show(LOAD_GAME, GameNotFound);
            else
                RequestFailureNotice.showHttpError(LOAD_GAME, error);
        });
    }

    // the board is the plain analysis one from here on, whether or not the game arrived
    private function finishImport(apply:Void->Void):Void
    {
        gameLoading = false;
        HaxeFolioApp.replacePath("analysis");
        apply();
        refreshLock();
        persistState();
    }

    private function play(ply:RawPly):Void
    {
        if (!isLoading())
            cursor.play(ply);
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
                if (markedNode != null && !cursor.tree.root.contains(markedNode))
                    markedNode = null;
                variationsCard.showTree(cursor.tree, selected);
                refreshCardPreview();
                studyMode.contentChanged();
            case Selection:
                variationsCard.select(selected);
        }
        refreshMoves();
        persistState();
    }

    private function togglePreviewMark():Void
    {
        if (draft != null || isLoading())
            return;

        markedNode = markedNode == cursor.selected ? null : cursor.selected;
        refreshCardPreview();
        studyMode.contentChanged();
        persistState();
    }

    private function setMarkedNode(node:Null<PlyTreeNode>):Void
    {
        markedNode = node;
        refreshCardPreview();
    }

    // a visitor sees no preview: it's the author's choice
    private function refreshCardPreview():Void
    {
        if (studyMode.isVisitorOpen())
            variationsCard.setCardPreview(null, false);
        else
            variationsCard.setCardPreview(StudyContent.previewNode(cursor.tree, markedNode), markedNode == null);
    }

    private function onStudyChanged():Void
    {
        analysisLayout.setStudyShown(studyMode.isShown());
        actionsCard.setSaveAsStudyShown(studyMode.status.match(None | Unavailable(_)));
        refreshCardPreview();
        refreshLock();
        fitLayoutHeight();

        var study:Null<Study> = studyMode.openStudy();
        if (study != null)
            setTitle(LocaleUtils.localeBinding("intellector.analysis.named_study_title"), study.details.name);
        else
            setTitle(GroupedLocaleResolvers.analysisTitle(studyMode.isShown()), studyId);
        persistState();
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

    private function playFromHere():Void
    {
        var position:Position = shownNode.position;
        ChallengeCreationLauncher.launch(draft -> ChallengePrefills.playFrom(draft, position));
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
        if (draft != null || isLoading())
            return;
        if (expanded)
            toggleExpanded();

        draft = new PositionDraft(shownNode.position);
        board.setPosition(draft.position, Replacement);
        board.setLastMove(null);
        board.setPolicy(new EditorMovePolicy());
        toolCard.select(FreeMove);
        onToolChosen(FreeMove);

        refreshLock();
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
        refreshLock();
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

    // while the editor is open or the study or the game loads
    private function refreshLock():Void
    {
        var loading:Bool = isLoading();
        var locked:Bool = draft != null || loading;
        variationsCard.setLocked(locked);
        movesCard.setLocked(locked);
        moveStrip.setLocked(locked);
        studyMode.setLocked(draft != null);
        actionsCard.setEnabled(!loading);
        if (draft == null)
            board.setPolicy(loading ? new InertMovePolicy() : analysisPolicy());
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

    private function openImport():Void
    {
        ImportPositionOverlay.present(importPosition);
    }

    private function importPosition(position:Position):Void
    {
        editDraft(() -> draft.setPosition(position));
    }

    private function refreshEditor():Void
    {
        editorCard.refresh(draft, cursor.tree.moveCount());
    }
}
