package client.datatypes.games;

enum FormulaNode
{
    Group(group:ConditionGroup);
    Leaf(condition:Condition);
}
