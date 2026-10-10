package client.ui.common.board.tools;

import client.ui.common.board.BoardInputOptions;
import client.ui.common.board.BoardPoint;
import client.ui.common.board.EditIntent;
import client.ui.common.board.HexTints;
import client.ui.common.board.MoveRulesAdapter;
import client.ui.common.board.PremoveIntent;
import client.ui.common.board.input.Modifiers;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceKind;
import intellectorboard.primitives.ply.RawPly;
import morestd.Detachable;
import morestd.Signal;
import testutils.Hexes.hex;
import testutils.Positions;
import testutils.board.FakeBoardView;
import testutils.board.FakeGestures;
import testutils.board.FakeHexFills;
import testutils.board.FakePremoveState;
import testutils.board.FakePrompts;
import utest.Assert;
import utest.Test;

class PieceMoveToolTest extends Test
{
    private static final SHIFT_HELD:Modifiers = {shift: true, ctrl: false};
    private static final DRAG_POINT:BoardPoint = {x: 123, y: 456};

    private var board:FakeBoardView;
    private var gestures:FakeGestures;
    private var prompts:FakePrompts;
    private var fills:FakeHexFills;
    private var options:BoardInputOptions;
    private var premoveState:FakePremoveState;

    // reported, described by `describePly`/`describePremove`/`describeEdit`
    private var played:Array<String>;
    private var premoveIntents:Array<String>;
    private var editIntents:Array<String>;

    private var tool:PieceMoveTool;
    private var binding:Detachable;

    private function setup():Void
    {
        board = new FakeBoardView(Position.defaultStarting());
        gestures = new FakeGestures();
        prompts = new FakePrompts();
        fills = new FakeHexFills();
        options = new BoardInputOptions();
        premoveState = new FakePremoveState(Black, true);

        played = [];
        premoveIntents = [];
        editIntents = [];

        var playMove:Signal<RawPly> = new Signal();
        playMove.subscribe(ply -> played.push(describePly(ply)));
        var premoveSignal:Signal<PremoveIntent> = new Signal();
        premoveSignal.subscribe(intent -> premoveIntents.push(describePremove(intent)));
        var editSignal:Signal<EditIntent> = new Signal();
        editSignal.subscribe(intent -> editIntents.push(describeEdit(intent)));

        var tints:HexTints = new HexTints(fills, FakeHexFills.PALETTE);
        tool = new PieceMoveTool(board, prompts, tints, options, new AnalysisMovePolicy(MoveRulesAdapter.DEFAULT), playMove, premoveSignal, editSignal);
        binding = tool.bind(gestures, Primary);
    }

    private static function describeHex(coords:HexCoords):String
    {
        return '${coords.i},${coords.j}';
    }

    private static function describePly(ply:RawPly):String
    {
        var description:String = '${describeHex(ply.from)}>${describeHex(ply.to)}';
        return ply.morphInto != null ? '$description=${ply.morphInto}' : description;
    }

    private static function describePremove(intent:PremoveIntent):String
    {
        return switch intent {
            case Queue(ply, null): 'queue ${describePly(ply)}';
            case Queue(ply, morphInto): 'queue ${describePly(ply)} as $morphInto';
            case CancelAll: "cancel";
        }
    }

    private static function describeEdit(intent:EditIntent):String
    {
        return switch intent {
            case MovePiece(from, to): 'move ${describeHex(from)}>${describeHex(to)}';
            case PlacePiece(coords, piece): 'place ${piece.type} ${describeHex(coords)}';
            case ClearHex(coords): 'clear ${describeHex(coords)}';
        }
    }

    private function useLiveGamePolicy():Void
    {
        tool.setPolicy(new LiveGameMovePolicy(MoveRulesAdapter.DEFAULT, White, premoveState));
    }

    // a White Progressor on (4, 1), a step from promoting
    private function showPromotionPosition():Void
    {
        board.setPosition(Positions.make(White, [
            {i: 0, j: 6, kind: Intellector, color: White},
            {i: 4, j: 1, kind: Progressor, color: White},
            {i: 8, j: 0, kind: Intellector, color: Black}
        ]), Replacement);
    }

    // a White Dominator on (4, 5) next to its Intellector, able to capture a Black Aggressor on (4, 2)
    private static function capturePosition():Position
    {
        return Positions.make(White, [
            {i: 4, j: 6, kind: Intellector, color: White},
            {i: 4, j: 5, kind: Dominator, color: White},
            {i: 4, j: 2, kind: Aggressor, color: Black},
            {i: 8, j: 0, kind: Intellector, color: Black}
        ]);
    }

    private function assertIdle(?pos:haxe.PosInfos):Void
    {
        Assert.same([], fills.filledScalars(), pos);
        Assert.same([], board.markerScalars(), pos);
        Assert.isTrue(board.piecesInPlace(), pos);
        Assert.isFalse(prompts.isOpen(), pos);
        Assert.isFalse(gestures.suspended, pos);
    }

    private function assertSelected(coords:HexCoords, ?pos:haxe.PosInfos):Void
    {
        Assert.equals("selectedDeparture", fills.entryAt(coords), pos);
    }

    private function testHoverTintsPiecesThatCanBePickedUp():Void
    {
        gestures.hover(hex(4, 5));
        Assert.equals("departureHover", fills.entryAt(hex(4, 5)));

        gestures.hover(hex(4, 1));
        Assert.same([], fills.filledScalars());

        gestures.hover(hex(4, 3));
        Assert.same([], fills.filledScalars());
    }

    private function testPressPicksUpPieceAndMarksDestinations():Void
    {
        gestures.press(Primary, hex(4, 5));

        assertSelected(hex(4, 5));
        Assert.same(Positions.sortedScalars([hex(3, 4), hex(4, 4), hex(5, 4)]), board.markerScalars());
    }

    private function testDragMovesPieceAndHighlightsDestinationUnderIt():Void
    {
        gestures.press(Primary, hex(4, 5));
        gestures.drag(Primary, hex(4, 4), DRAG_POINT);

        Assert.same(DRAG_POINT, board.pointOf(hex(4, 5)));
        Assert.equals("destinationHover", fills.entryAt(hex(4, 4)));

        gestures.drag(Primary, hex(4, 3), DRAG_POINT);

        Assert.isNull(fills.colorAt(hex(4, 4)));
        Assert.isNull(fills.colorAt(hex(4, 3)));
    }

    private function testDropOnDestinationPlaysMove():Void
    {
        gestures.press(Primary, hex(4, 5));
        gestures.drag(Primary, hex(4, 4));
        gestures.release(Primary, hex(4, 4));

        Assert.same(["4,5>4,4"], played);
        assertIdle();
    }

    private function testDropElsewhereAborts():Void
    {
        gestures.press(Primary, hex(4, 5));
        gestures.drag(Primary, hex(4, 2));
        gestures.release(Primary, hex(4, 2));

        Assert.same([], played);
        assertIdle();
    }

    private function testDropOffBoardAborts():Void
    {
        gestures.press(Primary, hex(4, 5));
        gestures.release(Primary, null);

        Assert.same([], played);
        assertIdle();
    }

    private function testClickSelectsThenClickOnDestinationPlaysMove():Void
    {
        gestures.click(Primary, hex(4, 5));

        assertSelected(hex(4, 5));
        Assert.isTrue(board.piecesInPlace());
        Assert.equals(3, board.markerScalars().length);

        gestures.hover(hex(4, 4));
        Assert.equals("destinationHover", fills.entryAt(hex(4, 4)));

        gestures.click(Primary, hex(4, 4));

        Assert.same(["4,5>4,4"], played);
        Assert.same([], board.markerScalars());
        Assert.isNull(fills.colorAt(hex(4, 5)));
    }

    private function testClickingSelectedPieceDeselects():Void
    {
        gestures.click(Primary, hex(4, 5));
        gestures.click(Primary, hex(4, 5));

        assertIdle();
    }

    private function testClickingAnotherOwnPieceSelectsIt():Void
    {
        gestures.click(Primary, hex(4, 5));
        gestures.click(Primary, hex(2, 5));

        Assert.isNull(fills.colorAt(hex(4, 5)));
        assertSelected(hex(2, 5));
        Assert.same([], played);
    }

    private function testClickingNonDestinationDeselects():Void
    {
        gestures.click(Primary, hex(4, 5));
        gestures.click(Primary, hex(4, 1));

        Assert.same([], played);
        assertIdle();
    }

    private function testPressOnNothingToPickUpCancelsPremoves():Void
    {
        gestures.press(Primary, hex(4, 3));
        gestures.press(Primary, null);

        Assert.same(["cancel", "cancel"], premoveIntents);
    }

    private function testEscapeDeselectsOrElseCancelsPremoves():Void
    {
        gestures.click(Primary, hex(4, 5));
        gestures.escape();

        assertIdle();
        Assert.same([], premoveIntents);

        gestures.escape();

        Assert.same(["cancel"], premoveIntents);
    }

    private function testPromotionAsksAndShowsMoveMeanwhile():Void
    {
        showPromotionPosition();
        gestures.press(Primary, hex(4, 1));
        gestures.release(Primary, hex(4, 0));

        Assert.isTrue(prompts.isOpen());
        Assert.same(FakePromptKind.Promotion, prompts.last.kind);
        Assert.isTrue(prompts.last.anchor.equals(hex(4, 0)));
        Assert.isTrue(gestures.suspended);
        Assert.equals("promptAnchor", fills.entryAt(hex(4, 0)));
        Assert.isTrue(board.hexOf(hex(4, 1)).equals(hex(4, 0)));
        Assert.isTrue(board.isHidden(hex(4, 0)));
        Assert.same([], played);

        prompts.choose(Aggressor);

        Assert.same(["4,1>4,0=Aggressor"], played);
        assertIdle();
        Assert.isFalse(board.isHidden(hex(4, 0)));
    }

    private function testCancelledPromotionReportsNothing():Void
    {
        showPromotionPosition();
        gestures.click(Primary, hex(4, 1));
        gestures.click(Primary, hex(4, 0));
        prompts.cancel();

        Assert.same([], played);
        assertIdle();
        Assert.isFalse(board.isHidden(hex(4, 0)));
    }

    private function testShiftAutoPromotesToDominator():Void
    {
        showPromotionPosition();
        gestures.press(Primary, hex(4, 1));
        gestures.release(Primary, hex(4, 0), SHIFT_HELD);

        Assert.isNull(prompts.last);
        Assert.same(["4,1>4,0=Dominator"], played);
    }

    private function testAutoPromotionPreferenceSkipsPrompt():Void
    {
        options.autoPromoteMode = ALWAYS;
        showPromotionPosition();
        gestures.click(Primary, hex(4, 1));
        gestures.click(Primary, hex(4, 0));

        Assert.same(["4,1>4,0=Dominator"], played);
    }

    private function testChameleonCaptureAsksWhetherToMorph():Void
    {
        board.setPosition(capturePosition(), Replacement);
        gestures.press(Primary, hex(4, 5));
        gestures.release(Primary, hex(4, 2));

        Assert.same(FakePromptKind.CaptureMorph(Aggressor), prompts.last.kind);

        prompts.decide(true);

        Assert.same(["4,5>4,2=Aggressor"], played);
        assertIdle();
    }

    private function testDeclinedChameleonPlaysPlainCapture():Void
    {
        board.setPosition(capturePosition(), Replacement);
        gestures.click(Primary, hex(4, 5));
        gestures.click(Primary, hex(4, 2));
        prompts.decide(false);

        Assert.same(["4,5>4,2"], played);
    }

    private function testPremovesAreQueuedWithoutMarkers():Void
    {
        useLiveGamePolicy();
        gestures.press(Primary, hex(4, 5));

        assertSelected(hex(4, 5));
        Assert.same([], board.markerScalars());

        gestures.release(Primary, hex(4, 4));

        Assert.same([], played);
        Assert.same(["queue 4,5>4,4"], premoveIntents);
    }

    private function testPremoveChameleonAsksOnlyWithShift():Void
    {
        useLiveGamePolicy();
        board.setPosition(capturePosition(), Replacement);

        gestures.press(Primary, hex(4, 5));
        gestures.release(Primary, hex(4, 2));

        Assert.isNull(prompts.last);
        Assert.same(["queue 4,5>4,2"], premoveIntents);

        gestures.press(Primary, hex(4, 5));
        gestures.release(Primary, hex(4, 2), SHIFT_HELD);

        Assert.same(FakePromptKind.PremoveChameleon(Dominator), prompts.last.kind);

        prompts.choose(Aggressor);

        Assert.same(["queue 4,5>4,2", "queue 4,5>4,2 as Aggressor"], premoveIntents);
    }

    private function testEditorMovesFreely():Void
    {
        tool.setPolicy(new EditorMovePolicy());
        gestures.press(Primary, hex(4, 1));

        Assert.same([], board.markerScalars());

        gestures.release(Primary, hex(4, 5));

        Assert.same(["move 4,1>4,5"], editIntents);
        Assert.same([], played);
    }

    private function testInertPolicyPicksNothingUp():Void
    {
        tool.setPolicy(new InertMovePolicy());
        gestures.hover(hex(4, 5));
        gestures.press(Primary, hex(4, 5));

        assertIdle();
        Assert.same(["cancel"], premoveIntents);
    }

    private function testSettingPolicyAbortsSelection():Void
    {
        gestures.hover(hex(4, 5));
        gestures.click(Primary, hex(4, 5));
        tool.setPolicy(new InertMovePolicy());

        assertIdle();
    }

    private function testReplacementDropsSelection():Void
    {
        gestures.click(Primary, hex(4, 5));
        board.setPosition(Position.defaultStarting(), Replacement);

        assertIdle();
    }

    private function testSelectionSurvivesMoveWhileStillPickable():Void
    {
        useLiveGamePolicy();
        gestures.click(Primary, hex(4, 5));

        // the opponent moves: the premove selection becomes a move one, with markers
        premoveState.turn = White;
        board.setPosition(Position.defaultStarting(), Move);

        assertSelected(hex(4, 5));
        Assert.equals(3, board.markerScalars().length);

        gestures.click(Primary, hex(4, 4));

        Assert.same(["4,5>4,4"], played);
    }

    private function testSelectionDropsOnMoveOnceUnpickable():Void
    {
        gestures.click(Primary, hex(4, 5));
        board.setPosition(Position.defaultStarting().copy(Black), Move);

        assertIdle();
    }

    private function testSelectionDropsOnMoveWhenPieceIsGone():Void
    {
        useLiveGamePolicy();
        gestures.click(Primary, hex(4, 5));

        var captured:Position = Position.defaultStarting();
        captured.setPiece(hex(4, 5), Aggressor, Black);
        board.setPosition(captured, Move);

        assertIdle();
    }

    private function testDragSurvivesMoveAndKeepsFollowingPointer():Void
    {
        useLiveGamePolicy();
        gestures.press(Primary, hex(4, 5));
        gestures.drag(Primary, hex(4, 4), DRAG_POINT);

        board.setPosition(Position.defaultStarting(), Move);

        Assert.same(DRAG_POINT, board.pointOf(hex(4, 5)));

        gestures.release(Primary, hex(4, 4));

        Assert.same(["queue 4,5>4,4"], premoveIntents);
    }

    private function testPremoveChoiceSurvivesMoveWhilePremovesQueued():Void
    {
        useLiveGamePolicy();
        board.setPosition(capturePosition(), Replacement);
        gestures.press(Primary, hex(4, 5));
        gestures.release(Primary, hex(4, 2), SHIFT_HELD);

        premoveState.queued = true;
        board.setPosition(capturePosition(), Move);

        Assert.isTrue(prompts.isOpen());
        Assert.isTrue(gestures.suspended);
        Assert.isTrue(board.hexOf(hex(4, 5)).equals(hex(4, 2)));
        Assert.isTrue(board.isHidden(hex(4, 2)));

        prompts.choose(Liberator);

        Assert.same(["queue 4,5>4,2 as Liberator"], premoveIntents);
    }

    private function testPremoveChoiceClosesOnMoveWithNothingQueued():Void
    {
        useLiveGamePolicy();
        board.setPosition(capturePosition(), Replacement);
        gestures.press(Primary, hex(4, 5));
        gestures.release(Primary, hex(4, 2), SHIFT_HELD);

        board.setPosition(capturePosition(), Move);

        assertIdle();
        Assert.same([], premoveIntents);
    }

    private function testPremoveChoiceClosesOnReplacementEvenWhilePremovesQueued():Void
    {
        useLiveGamePolicy();
        board.setPosition(capturePosition(), Replacement);
        gestures.press(Primary, hex(4, 5));
        gestures.release(Primary, hex(4, 2), SHIFT_HELD);

        premoveState.queued = true;
        board.setPosition(capturePosition(), Replacement);

        assertIdle();
    }

    private function testMoveChoiceClosesOnAnyPositionChange():Void
    {
        showPromotionPosition();
        gestures.click(Primary, hex(4, 1));
        gestures.click(Primary, hex(4, 0));
        board.setPosition(board.getPosition(), Move);

        assertIdle();
        Assert.same([], played);
    }

    private function testUnbindingAbortsGestureAndHover():Void
    {
        gestures.hover(hex(2, 5));
        gestures.press(Primary, hex(4, 5));
        gestures.drag(Primary, hex(4, 4));
        binding.detach();

        assertIdle();

        gestures.release(Primary, hex(4, 4));

        Assert.same([], played);
    }

    private function testUnbindingClosesPrompt():Void
    {
        showPromotionPosition();
        gestures.click(Primary, hex(4, 1));
        gestures.click(Primary, hex(4, 0));
        binding.detach();

        assertIdle();
    }
}
