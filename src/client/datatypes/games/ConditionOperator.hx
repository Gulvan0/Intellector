package client.datatypes.games;

/** By its name in the formula format **/
enum abstract ConditionOperator(String) from String to String
{
    var LT = "lt";
    var GT = "gt";
    var LE = "le";
    var GE = "ge";
    var EQ = "eq";
    var BETWEEN = "between";
    var UNKNOWN = "unknown";
}
