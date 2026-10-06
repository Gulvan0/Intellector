package client.datatypes;

import intellectorboard.primitives.piece.PieceColor;

@:using(client.datatypes.ChallengeAcceptorColor.ChallengeAcceptorColorExtension)
enum ChallengeAcceptorColor
{
    White;
    Black;
    Random;
}

class ChallengeAcceptorColorExtension
{
    public static function getColor(acceptorColor:ChallengeAcceptorColor):Null<PieceColor>
    {
        return switch acceptorColor {
            case White: White;
            case Black: Black;
            case Random: null;
        }
    }
}
