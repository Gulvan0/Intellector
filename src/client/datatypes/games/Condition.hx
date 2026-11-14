package client.datatypes.games;

/**
    A property condition, possibly partially filled while it is being added or edited: the
    parameter, the operator and the operands, or the values, come one step at a time.
**/
class Condition
{
    public final property:GameProperty;
    /** Parametrized properties only **/
    public var parameter:Null<ConditionParameter>;
    /** Operator condition properties only **/
    public var conditionOperator:Null<ConditionOperator>;
    public var operands:Array<Operand>;
    /** Sole equality condition properties only; in the selector's order **/
    public var values:Array<EqualityValue>;

    public function new(property:GameProperty, ?parameter:ConditionParameter, ?conditionOperator:ConditionOperator, ?operands:Array<Operand>, ?values:Array<EqualityValue>)
    {
        this.property = property;
        this.parameter = parameter;
        this.conditionOperator = conditionOperator;
        this.operands = operands ?? [];
        this.values = values ?? [];
    }

    public function copy():Condition
    {
        return new Condition(property, parameter, conditionOperator, operands.copy(), values.copy());
    }
}
