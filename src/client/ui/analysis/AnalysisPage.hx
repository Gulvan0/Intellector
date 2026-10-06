package client.ui.analysis;

import haxe.Timer;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;
import morestd.Detachable;
import morestd.MathTools;
import intellectorboard.movement.rules.PlyRules;
import intellectorboard.primitives.piece.PieceData;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;
import client.datatypes.BoardCoordinatesMode;
import client.datatypes.PlyHistory;
import client.datatypes.PlyHistory.ShownPly;
import client.datatypes.PlyNavigationType;
import client.ui.common.board.EditIntent;
import client.ui.common.board.EditMode;
import client.ui.common.board.BoardSurface;
import client.ui.common.board.InteractiveBoard;
import client.ui.common.board.MoveRulesAdapter;
import client.ui.common.board.tools.AnalysisMovePolicy;
import client.ui.common.board.tools.EditorMovePolicy;
import client.ui.common.board.tools.InertMovePolicy;
import client.ui.common.board.tools.LiveGameMovePolicy;
import client.ui.common.board.tools.PieceMovePolicy;
import client.ui.common.board.Premoves;

class AnalysisPage extends PageBase
{
    // temporary: the replies harness's thinking time
    private static inline final HARNESS_REPLY_DELAY_MS:Int = 3000;

    private final studyId:Null<Int>;
    private var mainBoard:InteractiveBoard;
    private var playMoveHandle:Detachable;
    private var editIntentsHandle:Detachable;

    private var history:PlyHistory;
    private var historyHandle:Detachable;
    private var browsingHistory:Bool = false;

    // while the temporary editor controls are in use
    private var editedPosition:Null<Position> = null;

    // temporary: the user plays White against random replies, with premoves
    private var harnessButton:Button;
    private var harnessPremoves:Null<Premoves> = null;
    private var harnessTimer:Null<Timer> = null;

    public function new(?studyId:Null<Int>)
    {
        super();
        this.studyId = studyId;
    }

    private override function init():Void
    {
        var titleKey:String = GroupedLocaleResolvers.analysisTitle(studyId != null);
        setTitle(titleKey, studyId);

        var content:VBox = new VBox();
        content.percentWidth = 100;
        addComponent(content);

        var label:Label = new Label();
        label.text = LocaleUtils.resolveText(titleKey, studyId);
        content.addComponent(label);

        // temporary: local hot-seat play until the position editor and analysis session replace it
        var startingPosition:Position = Position.defaultStarting();

        mainBoard = new InteractiveBoard(startingPosition, White, new AnalysisMovePolicy(MoveRulesAdapter.DEFAULT));
        content.addComponent(mainBoard);
        playMoveHandle = mainBoard.playMove.subscribe(onMoveChosen);
        editIntentsHandle = mainBoard.editIntents.subscribe(onEdit);
        startHistory(startingPosition);

        var debugRow:HBox = new HBox();
        content.addComponent(debugRow);

        // temporary: until a page has a real flip control
        var flipButton:Button = new Button();
        flipButton.text = "Flip";
        flipButton.onClick = _ -> mainBoard.setOrientation(mainBoard.getOrientation() == White ? Black : White);
        debugRow.addComponent(flipButton);

        // temporary: until the page has its real history controls
        var navigations:Array<{text:String, type:PlyNavigationType}> = [
            {text: "|<", type: Start},
            {text: "<", type: Previous},
            {text: ">", type: Next},
            {text: ">|", type: End}
        ];
        for (navigation in navigations)
        {
            var button:Button = new Button();
            button.text = navigation.text;
            button.onClick = _ -> history.navigate(navigation.type);
            debugRow.addComponent(button);
        }

        // temporary: White against random replies; premoves follow the preference
        harnessButton = new Button();
        harnessButton.text = "Replies harness";
        harnessButton.toggle = true;
        harnessButton.onChange = _ -> setHarnessEnabled(harnessButton.selected);
        debugRow.addComponent(harnessButton);

        // temporary: until the position editor has its real UI
        var editRow:HBox = new HBox();
        content.addComponent(editRow);
        var editModes:Array<{text:String, mode:EditMode}> = [
            {text: "Edit: move", mode: Moving},
            {text: "Place white Aggressor", mode: Placing(new PieceData(Aggressor, White))},
            {text: "Place black Dominator", mode: Placing(new PieceData(Dominator, Black))},
            {text: "Clear", mode: Clearing}
        ];
        for (editMode in editModes)
        {
            var button:Button = new Button();
            button.text = editMode.text;
            button.onClick = _ -> startEditing(editMode.mode);
            editRow.addComponent(button);
        }
        var doneButton:Button = new Button();
        doneButton.text = "Done editing";
        doneButton.onClick = _ -> stopEditing();
        editRow.addComponent(doneButton);

        var previewRow:HBox = new HBox();
        previewRow.percentWidth = 100;
        content.addComponent(previewRow);

        var previewModes:Array<BoardCoordinatesMode> = [NONE, FILES_ONLY, ALL];
        var previewOrientations:Array<PieceColor> = [White, Black, White];

        for (i in 0...previewModes.length)
        {
            var previewWrapper:VBox = new VBox();
            previewWrapper.width = 150;

            // fixed position and coordinates mode: a demo of all three modes
            var preview:BoardSurface = new BoardSurface(Position.defaultStarting(), previewOrientations[i], previewModes[i]);
            previewWrapper.addComponent(preview);
            previewRow.addComponent(previewWrapper);
        }
    }

    private function onMoveChosen(ply:RawPly):Void
    {
        // moves only happen at the latest position, so the view follows
        history.append(ply, true);

        if (harnessPremoves != null && history.latestPosition().turnColor == Black)
            scheduleHarnessReply();
    }

    // hot-seat analysis, or White's side against the harness
    private function livePolicy():PieceMovePolicy
    {
        return harnessPremoves != null
            ? new LiveGameMovePolicy(MoveRulesAdapter.DEFAULT, White, harnessPremoves)
            : new AnalysisMovePolicy(MoveRulesAdapter.DEFAULT);
    }

    private function setHarnessEnabled(enabled:Bool):Void
    {
        stopHarnessTimer();

        if (enabled)
        {
            stopEditing();
            harnessPremoves = mainBoard.enablePremoves(White, MoveRulesAdapter.DEFAULT);
            if (history.latestPosition().turnColor == Black)
                scheduleHarnessReply();
        }
        else
        {
            harnessPremoves = null;
            mainBoard.disablePremoves();
        }

        if (!browsingHistory && editedPosition == null)
            mainBoard.setPolicy(livePolicy());
    }

    private function scheduleHarnessReply():Void
    {
        stopHarnessTimer();
        harnessTimer = Timer.delay(() -> {
            harnessTimer = null;
            var replies:Array<RawPly> = PlyRules.possiblePlys(history.latestPosition());
            if (replies.length == 0)
                return;
            history.append(MathTools.randomElement(replies), PlyHistory.followsLatestMove(Preferences.followLatestMove.get(), true));
        }, HARNESS_REPLY_DELAY_MS);
    }

    private function stopHarnessTimer():Void
    {
        if (harnessTimer != null)
            harnessTimer.stop();
        harnessTimer = null;
    }

    private function startHistory(startingPosition:Position):Void
    {
        if (historyHandle != null)
            historyHandle.detach();

        history = new PlyHistory(startingPosition);
        historyHandle = history.onShownChanged.subscribe(onShownChanged);
    }

    private function onShownChanged(shown:ShownPly):Void
    {
        mainBoard.setPosition(shown.position, shown.cause);
        mainBoard.setLastMove(shown.lastMove);

        // a linear history has nowhere to put a move made from an older position
        var browsing:Bool = !history.isShowingLatest();
        if (browsing != browsingHistory)
        {
            browsingHistory = browsing;
            mainBoard.setPolicy(browsing ? new InertMovePolicy() : livePolicy());
        }
    }

    private function startEditing(mode:EditMode):Void
    {
        if (harnessButton.selected)
            harnessButton.selected = false;

        if (editedPosition == null)
        {
            editedPosition = history.shownPosition().copy();
            mainBoard.setPosition(editedPosition, Replacement);
            mainBoard.setLastMove(null);
            mainBoard.setPolicy(new EditorMovePolicy());
        }
        mainBoard.setEditMode(mode);
    }

    private function stopEditing():Void
    {
        if (editedPosition == null)
            return;

        var position:Position = editedPosition;
        editedPosition = null;
        mainBoard.setEditMode(Moving);
        browsingHistory = false;
        mainBoard.setPolicy(livePolicy());
        startHistory(position);
    }

    private function onEdit(intent:EditIntent):Void
    {
        if (editedPosition == null)
            return;

        var position:Position = editedPosition.copy();
        switch intent
        {
            case MovePiece(from, to):
                position.set(to, position.get(from));
                position.set(from, Empty);
            case PlacePiece(hex, piece):
                position.set(hex, Occupied(piece));
            case ClearHex(hex):
                position.set(hex, Empty);
        }

        editedPosition = position;
        mainBoard.setPosition(position, Replacement);
    }

    private override function onClose():Void
    {
        stopHarnessTimer();
        playMoveHandle.detach();
        editIntentsHandle.detach();
        historyHandle.detach();
        mainBoard.dispose();
    }
}
