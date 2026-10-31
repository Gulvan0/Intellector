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

    /** The other side's colour **/
    public static function opposite(acceptorColor:ChallengeAcceptorColor):ChallengeAcceptorColor
    {
        return switch acceptorColor {
            case White: Black;
            case Black: White;
            case Random: Random;
        }
    }
}
