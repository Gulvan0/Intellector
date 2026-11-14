package client.logic.games;

import client.datatypes.games.ConditionGroup;
import client.datatypes.games.FormulaNode;

typedef FormulaCounts =
{
    /** Recursive layers, the root included **/
    depth:Int,
    leaves:Int,
    /** Leaves and recursive conditions, the root included **/
    nodes:Int,
    costlyLeaves:Int,
    /** The most values a single leaf holds **/
    maxValues:Int
}

/** The formula's caps, mirroring the server's `game/archive/constants.py` **/
class FormulaCaps
{
    public static inline final MAX_DEPTH:Int = 8;
    public static inline final MAX_LEAVES:Int = 50;
    public static inline final MAX_NODES:Int = 100;
    public static inline final MAX_VALUES_PER_LEAF:Int = 100;
    public static inline final MAX_COSTLY_LEAVES:Int = 10;
    public static inline final MAX_FORMULA_LENGTH:Int = 8 * 1024;

    public static function count(root:ConditionGroup):FormulaCounts
    {
        var counts:FormulaCounts = {depth: 0, leaves: 0, nodes: 0, costlyLeaves: 0, maxValues: 0};
        countGroup(root, 1, counts);
        return counts;
    }

    /** Whether the formula is within all of the caps but the serialized length **/
    public static function fits(root:ConditionGroup):Bool
    {
        var counts:FormulaCounts = count(root);
        return counts.depth <= MAX_DEPTH
            && counts.leaves <= MAX_LEAVES
            && counts.nodes <= MAX_NODES
            && counts.costlyLeaves <= MAX_COSTLY_LEAVES
            && counts.maxValues <= MAX_VALUES_PER_LEAF;
    }

    /** Whether one more leaf fits **/
    public static function canAddLeaf(counts:FormulaCounts):Bool
    {
        return counts.leaves < MAX_LEAVES && counts.nodes < MAX_NODES;
    }

    /** Whether a recursive condition fits as a child of a group at `parentDepth` (the root being at 1) **/
    public static function canAddGroup(counts:FormulaCounts, parentDepth:Int):Bool
    {
        return counts.nodes < MAX_NODES && parentDepth < MAX_DEPTH;
    }

    public static function canAddCostlyLeaf(counts:FormulaCounts):Bool
    {
        return canAddLeaf(counts) && counts.costlyLeaves < MAX_COSTLY_LEAVES;
    }

    private static function countGroup(group:ConditionGroup, depth:Int, counts:FormulaCounts):Void
    {
        counts.nodes++;
        if (depth > counts.depth)
            counts.depth = depth;

        for (child in group.children)
            switch child
            {
                case Group(subgroup):
                    countGroup(subgroup, depth + 1, counts);
                case Leaf(condition):
                    counts.nodes++;
                    counts.leaves++;
                    if (PropertyCatalog.isCostly(condition.property))
                        counts.costlyLeaves++;
                    if (condition.values.length > counts.maxValues)
                        counts.maxValues = condition.values.length;
            }
    }
}
