package client.logic.games;

import client.datatypes.games.Condition;
import client.datatypes.games.ConditionOperator;
import client.datatypes.games.GameProperty;
import client.datatypes.games.OperandType;
import client.datatypes.games.ParameterType;

/** What each game property takes: its condition kind, parameter, operators and operand type **/
class PropertyCatalog
{
    /** In the order the condition kind step offers them **/
    public static final ALL:Array<GameProperty> = [
        STARTED_AT,
        ENDED_AT,
        INITIAL_TIME,
        BONUS_TIME,
        DURATION,
        TIME_LEFT,
        MOVE_CNT,
        ELO,
        PLAYER,
        TIME_CONTROL_KIND,
        RATED,
        OUTCOME,
        STARTING_POSITION,
        OPENING,
        ELO_PROVISIONAL,
        WINNER,
        RESULT
    ];

    /** In the order the operator step offers them **/
    private static final OPERATOR_ORDER:Array<ConditionOperator> = [LT, GT, LE, GE, EQ, BETWEEN, UNKNOWN];

    /** Null for a sole equality property **/
    public static function operandType(property:GameProperty):Null<OperandType>
    {
        return switch property {
            case STARTED_AT | ENDED_AT: DateTimeOperand;
            case INITIAL_TIME | BONUS_TIME | DURATION | TIME_LEFT: DurationOperand;
            case MOVE_CNT | ELO: IntOperand;
            default: null;
        }
    }

    public static function isOperatorProperty(property:GameProperty):Bool
    {
        return operandType(property) != null;
    }

    /** Empty for a sole equality property **/
    public static function operators(property:GameProperty):Array<ConditionOperator>
    {
        var type:Null<OperandType> = operandType(property);
        if (type == null)
            return [];

        var allowed:Array<ConditionOperator> = switch type {
            case DateTimeOperand: [LT, GT, BETWEEN];
            case DurationOperand: [LT, GT, LE, GE, BETWEEN];
            case IntOperand: [LT, GT, LE, GE, EQ, BETWEEN];
        }
        if (allowsUnknown(property))
            allowed.push(UNKNOWN);
        return OPERATOR_ORDER.filter(candidate -> allowed.contains(candidate));
    }

    /** Whether the property may be unrecorded, so that UNKNOWN tests for it **/
    public static function allowsUnknown(property:GameProperty):Bool
    {
        return switch property {
            case STARTED_AT | ENDED_AT | DURATION | TIME_LEFT: true;
            default: false;
        }
    }

    /** Null for a property without a parameter **/
    public static function parameterType(property:GameProperty):Null<ParameterType>
    {
        return switch property {
            case PLAYER: OptionalColor;
            case TIME_LEFT: PlayerOrColor;
            case ELO | ELO_PROVISIONAL: UserOrColor;
            default: null;
        }
    }

    /** Whether the property takes exactly one value rather than a list of them **/
    public static function isSingleValued(property:GameProperty):Bool
    {
        return property == RATED || property == ELO_PROVISIONAL;
    }

    /** Opening and starting position conditions, capped by `FormulaCaps.MAX_COSTLY_LEAVES` **/
    public static function isCostly(property:GameProperty):Bool
    {
        return property == OPENING || property == STARTING_POSITION;
    }

    public static function operandCount(conditionOperator:ConditionOperator):Int
    {
        return switch conditionOperator {
            case BETWEEN: 2;
            case UNKNOWN: 0;
            default: 1;
        }
    }

    /** Whether every step of the condition's flow has been completed **/
    public static function isComplete(condition:Condition):Bool
    {
        if (parameterType(condition.property) != null && condition.parameter == null)
            return false;

        if (!isOperatorProperty(condition.property))
            return condition.values.length > 0;

        return condition.conditionOperator != null && condition.operands.length == operandCount(condition.conditionOperator);
    }
}
