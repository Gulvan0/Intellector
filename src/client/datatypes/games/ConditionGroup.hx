package client.datatypes.games;

/**
    A recursive condition: AND or OR over its children, or NOT over its only child (none while
    unspecified). A formula's root is an AND.
**/
class ConditionGroup
{
    public var kind:GroupKind;
    public final children:Array<FormulaNode>;

    public function new(kind:GroupKind, ?children:Array<FormulaNode>)
    {
        this.kind = kind;
        this.children = children ?? [];
    }

    /** The empty formula: a root AND without conditions **/
    public static function emptyRoot():ConditionGroup
    {
        return new ConditionGroup(AND);
    }

    public function copy():ConditionGroup
    {
        return new ConditionGroup(kind, children.map(copyNode));
    }

    private static function copyNode(node:FormulaNode):FormulaNode
    {
        return switch node {
            case Group(group): Group(group.copy());
            case Leaf(condition): Leaf(condition.copy());
        }
    }
}
