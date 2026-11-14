package client.logic.games;

import client.datatypes.games.Condition;
import client.datatypes.games.ConditionGroup;
import client.datatypes.games.FormulaNode;
import utest.Assert;
import utest.Test;

class FormulaFinalizerTest extends Test
{
    private function testRemovesPartialConditions():Void
    {
        var root:ConditionGroup = new ConditionGroup(AND, [
            Leaf(new Condition(RATED, null, null, null, [IsBool(true)])),
            Leaf(new Condition(ELO)),
            Leaf(new Condition(ELO, OfColor(White))),
            Leaf(new Condition(MOVE_CNT, null, BETWEEN, [IntValue(10)])),
            Leaf(new Condition(PLAYER, EitherColor))
        ]);
        FormulaFinalizer.finalize(root);
        Assert.equals('{"version":1,"root":{"and":[{"property":"rated","values":[true]}]}}', FormulaCodec.encode(root));
    }

    private function testRemovesGroupsLeftEmptyAtEveryLevel():Void
    {
        var root:ConditionGroup = new ConditionGroup(AND, [
            Group(new ConditionGroup(OR, [
                Group(new ConditionGroup(NOT)),
                Group(new ConditionGroup(AND, [Leaf(new Condition(ELO))]))
            ])),
            Group(new ConditionGroup(NOT, [Group(new ConditionGroup(OR))])),
            Group(new ConditionGroup(OR, [Leaf(new Condition(MOVE_CNT, null, BETWEEN))])),
            Leaf(new Condition(DURATION, null, UNKNOWN))
        ]);
        FormulaFinalizer.finalize(root);
        Assert.equals('{"version":1,"root":{"and":[{"property":"duration","operator":"unknown","operands":[]}]}}', FormulaCodec.encode(root));
    }

    private function testKeepsEmptyRoot():Void
    {
        var root:ConditionGroup = new ConditionGroup(AND, [Group(new ConditionGroup(NOT))]);
        FormulaFinalizer.finalize(root);
        Assert.equals(client.datatypes.games.GroupKind.AND, root.kind);
        Assert.equals(0, root.children.length);
    }
}
