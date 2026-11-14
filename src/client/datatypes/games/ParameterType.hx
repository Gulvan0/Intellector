package client.datatypes.games;

/** What a parametrized property is parametrized by **/
enum ParameterType
{
    /** Any, white or black **/
    OptionalColor;
    /** White, black or a player **/
    PlayerOrColor;
    /** White, black or a user **/
    UserOrColor;
}
