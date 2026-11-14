package client.datatypes.games;

enum Operand
{
    DateTimeValue(value:LocalDateTime);
    /** Whole milliseconds **/
    DurationValue(ms:Float);
    IntValue(value:Int);
}
