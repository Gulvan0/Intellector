package client.ui.common.board.tools;

import client.ui.common.board.MoveRules;
import client.ui.common.board.MoveRulesAdapter;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceKind;
import testutils.Hexes.hex;
import testutils.Positions;
import testutils.board.FakePremoveState;
import utest.Assert;
import utest.Test;

class LiveGameMovePolicyTest extends Test
{
    private var premoves:FakePremoveState;
    private var policy:LiveGameMovePolicy;

    private function setup():Void
    {
        premoves = new FakePremoveState(White, true);
        policy = new LiveGameMovePolicy(MoveRulesAdapter.DEFAULT, White, premoves);
    }

    // White's `mover` on (4, 5), able to reach a Black Aggressor on (4, 2); White's Intellector adjacent or not
    private static function capturePosition(mover:PieceKind, withAura:Bool):Position
    {
        return Positions.make(White, [
            {i: withAura ? 4 : 0, j: 6, kind: Intellector, color: White},
            {i: 4, j: 5, kind: mover, color: White},
            {i: 4, j: 2, kind: Aggressor, color: Black},
            {i: 8, j: 0, kind: Intellector, color: Black}
        ]);
    }

    private function testMovesOnOwnRealTurn():Void
    {
        Assert.equals(PieceMoveMode.Move, policy.pickMode(Position.defaultStarting()));
    }

    private function testPremovesOnOpponentsRealTurn():Void
    {
        premoves.turn = Black;

        Assert.equals(PieceMoveMode.Premove, policy.pickMode(Position.defaultStarting()));
    }

    private function testTurnIsTakenFromRealPositionNotShownOne():Void
    {
        premoves.turn = Black;

        Assert.equals(PieceMoveMode.Premove, policy.pickMode(Position.defaultStarting().copy(White)));
    }

    private function testNothingMovesOnOpponentsTurnWithPremovesDisabled():Void
    {
        premoves.turn = Black;
        premoves.enabled = false;

        Assert.isNull(policy.pickMode(Position.defaultStarting()));
    }

    private function testWithoutPremovesTurnIsTheShownPositions():Void
    {
        var withoutPremoves:LiveGameMovePolicy = new LiveGameMovePolicy(MoveRulesAdapter.DEFAULT, White, null);

        Assert.equals(PieceMoveMode.Move, withoutPremoves.pickMode(Position.defaultStarting()));
        Assert.isNull(withoutPremoves.pickMode(Position.defaultStarting().copy(Black)));
        Assert.isFalse(withoutPremoves.keepsChoiceAcrossMove(Position.defaultStarting()));
    }

    private function testOnlyOwnPiecesCanBePickedUpInEitherMode():Void
    {
        var position:Position = Position.defaultStarting();

        for (mode in [PieceMoveMode.Move, PieceMoveMode.Premove])
        {
            Assert.isTrue(policy.canPickUp(position, mode, hex(4, 5)));
            Assert.isFalse(policy.canPickUp(position, mode, hex(4, 1)));
            Assert.isFalse(policy.canPickUp(position, mode, hex(4, 3)));
        }
    }

    private function testPremoveDestinationsIgnoreBlockers():Void
    {
        var position:Position = Position.defaultStarting();
        var aggressor:HexCoords = hex(2, 6);

        Assert.same(
            Positions.sortedScalars(MoveRulesAdapter.DEFAULT.getPremoveDestinations(aggressor, position.pieces)),
            Positions.sortedScalars(policy.destinations(position, Premove, aggressor))
        );
        Assert.isTrue(policy.destinations(position, Premove, aggressor).length > policy.destinations(position, Move, aggressor).length);
    }

    private function testMarkersOnlyForMoves():Void
    {
        Assert.isTrue(policy.showsMarkers(Move));
        Assert.isFalse(policy.showsMarkers(Premove));
    }

    private function testMoveCompletionFollowsTheRules():Void
    {
        Assert.same(CompletionKind.Chameleon(Aggressor), policy.completion(capturePosition(Dominator, true), Move, hex(4, 5), hex(4, 2)));
    }

    private function testPremovePromotes():Void
    {
        var position:Position = Positions.make(White, [
            {i: 0, j: 6, kind: Intellector, color: White},
            {i: 4, j: 1, kind: Progressor, color: White},
            {i: 8, j: 0, kind: Intellector, color: Black}
        ]);

        Assert.same(CompletionKind.Promotion, policy.completion(position, Premove, hex(4, 1), hex(4, 0)));
    }

    private function testPremoveWithinAuraMayBecomeChameleonWhateverTheTarget():Void
    {
        Assert.same(CompletionKind.PremoveChameleon, policy.completion(capturePosition(Dominator, true), Premove, hex(4, 5), hex(4, 2)));
        Assert.same(CompletionKind.PremoveChameleon, policy.completion(capturePosition(Dominator, true), Premove, hex(4, 5), hex(4, 3)));
    }

    private function testPremoveOutsideAuraNeedsNothing():Void
    {
        Assert.same(CompletionKind.None, policy.completion(capturePosition(Dominator, false), Premove, hex(4, 5), hex(4, 2)));
    }

    private function testProgressorAndIntellectorPremovesNeverBecomeChameleons():Void
    {
        var auraEverywhere:MoveRules = {
            getLegalDestinations: MoveRulesAdapter.DEFAULT.getLegalDestinations,
            getPremoveDestinations: MoveRulesAdapter.DEFAULT.getPremoveDestinations,
            isPromotionPossible: MoveRulesAdapter.DEFAULT.isPromotionPossible,
            isChameleonPossible: MoveRulesAdapter.DEFAULT.isChameleonPossible,
            isAuraActive: (_, _) -> true
        };
        var auraPolicy:LiveGameMovePolicy = new LiveGameMovePolicy(auraEverywhere, White, premoves);
        var position:Position = Position.defaultStarting();

        Assert.same(CompletionKind.None, auraPolicy.completion(position, Premove, hex(4, 5), hex(4, 4)));
        Assert.same(CompletionKind.None, auraPolicy.completion(position, Premove, hex(4, 6), hex(4, 5)));
        Assert.same(CompletionKind.PremoveChameleon, auraPolicy.completion(position, Premove, hex(2, 6), hex(2, 2)));
    }

    private function testDefensorSwapWithOwnIntellectorIsNoChameleon():Void
    {
        var position:Position = capturePosition(Defensor, true);

        Assert.same(CompletionKind.None, policy.completion(position, Premove, hex(4, 5), hex(4, 6)));
        Assert.same(CompletionKind.PremoveChameleon, policy.completion(position, Premove, hex(4, 5), hex(4, 4)));
    }

    private function testChoiceSurvivesMoveWhilePremovesQueued():Void
    {
        Assert.isFalse(policy.keepsChoiceAcrossMove(Position.defaultStarting()));

        premoves.queued = true;

        Assert.isTrue(policy.keepsChoiceAcrossMove(Position.defaultStarting()));
    }
}
