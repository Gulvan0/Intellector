package client.datatypes.games;

/** A recursive condition, by its key in the formula format **/
enum abstract GroupKind(String) from String to String
{
    var AND = "and";
    var OR = "or";
    var NOT = "not";
}
