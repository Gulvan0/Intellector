package client.logic.games;

import client.datatypes.games.Condition;
import client.datatypes.games.ConditionGroup;
import client.datatypes.games.FormulaNode;
import client.logic.games.FormulaCaps.FormulaCounts;
import utest.Assert;
import utest.Test;

class FormulaCapsTest extends Test
{
    private function testCountsPartialConditionsAndGroups():Void
    {
        var root:ConditionGroup = new ConditionGroup(AND, [
            Leaf(new Condition(OPENING, null, null, null, [IsOpening(1), IsOpening(2), IsOpening(3)])),
            Group(new ConditionGroup(NOT, [Group(new ConditionGroup(OR, [Leaf(new Condition(STARTING_POSITION))]))]))
        ]);
        var counts:FormulaCounts = FormulaCaps.count(root);
        Assert.equals(3, counts.depth);
        Assert.equals(2, counts.leaves);
        Assert.equals(5, counts.nodes);
        Assert.equals(2, counts.costlyLeaves);
        Assert.equals(3, counts.maxValues);
    }

    private function testAddingLimits():Void
    {
        var full:ConditionGroup = new ConditionGroup(AND, [for (_ in 0...FormulaCaps.MAX_LEAVES) Leaf(new Condition(RATED))]);
        Assert.isFalse(FormulaCaps.canAddLeaf(FormulaCaps.count(full)));
        Assert.isTrue(FormulaCaps.canAddGroup(FormulaCaps.count(full), 1));
        Assert.isFalse(FormulaCaps.canAddGroup(FormulaCaps.count(full), FormulaCaps.MAX_DEPTH));

        var costly:ConditionGroup = new ConditionGroup(AND, [for (_ in 0...FormulaCaps.MAX_COSTLY_LEAVES) Leaf(new Condition(OPENING))]);
        Assert.isTrue(FormulaCaps.canAddLeaf(FormulaCaps.count(costly)));
        Assert.isFalse(FormulaCaps.canAddCostlyLeaf(FormulaCaps.count(costly)));
    }
}
