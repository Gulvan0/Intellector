package client.logic.games;

import client.datatypes.games.ConditionGroup;
import client.datatypes.games.FormulaNode;

/**
    Brings the formula box's formula to the shape a search or a save uses: partially filled
    conditions go, then the recursive conditions left without a subcondition, except the root.
**/
class FormulaFinalizer
{
    /** Finalizes `root` in place **/
    public static function finalize(root:ConditionGroup):Void
    {
        prune(root);
    }

    // Children first, so that a group emptied by its children's removal goes as well
    private static function prune(group:ConditionGroup):Void
    {
        var kept:Array<FormulaNode> = [];
        for (child in group.children)
            switch child
            {
                case Leaf(condition):
                    if (PropertyCatalog.isComplete(condition))
                        kept.push(child);
                case Group(subgroup):
                    prune(subgroup);
                    if (subgroup.children.length > 0)
                        kept.push(child);
            }

        group.children.resize(0);
        for (child in kept)
            group.children.push(child);
    }
}
