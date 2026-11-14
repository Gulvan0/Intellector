package client.datatypes.games;

import intellectorboard.primitives.piece.PieceColor;

/** The side or player a parametrized property is taken of **/
enum ConditionParameter
{
    EitherColor;
    OfColor(color:PieceColor);
    OfPlayer(player:PlayerValue);
}
