package client.datatypes.games;

/** What a `DateTime` operand bounds, which decides what it resolves to **/
enum DateTimeBound
{
    /** `<` **/
    Before;
    /** `>` **/
    After;
    /** BETWEEN's lower bound **/
    FromInclusive;
    /** BETWEEN's upper bound **/
    UpToInclusive;
}
