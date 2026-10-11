package client.datatypes.challenge;

import intellectorboard.primitives.piece.PieceColor;

@:using(client.datatypes.challenge.ChallengeAcceptorColor.ChallengeAcceptorColorExtension)
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
