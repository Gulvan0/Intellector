package net.models.common.mappers;

class PieceColorMapper
{
    public static function datatypeToDto(datatype:lib.intellectorboard.primitives.piece.PieceColor):net.models.common.PieceColor
    {
        return switch datatype {
            case White: WHITE
            case Black: BLACK
        }
    }

    public static function dtoToDatatype(dto:net.models.common.PieceColor):lib.intellectorboard.primitives.piece.PieceColor
    {
        return switch dto {
            case WHITE: White
            case BLACK: Black
        }
    }
}
