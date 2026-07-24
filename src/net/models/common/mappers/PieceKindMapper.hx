package net.models.common.mappers;

class PieceKindMapper
{
    public static function datatypeToDto(datatype:lib.intellectorboard.primitives.piece.PieceKind):net.models.common.PieceKind
    {
        return switch datatype {
            case Progressor: PROGRESSOR;
            case Aggressor: AGGRESSOR;
            case Dominator: DOMINATOR;
            case Liberator: LIBERATOR;
            case Defensor: DEFENSOR;
            case Intellector: INTELLECTOR;
        }
    }

    public static function dtoToDatatype(dto:net.models.common.PieceKind):lib.intellectorboard.primitives.piece.PieceKind
    {
        return switch dto {
            case PROGRESSOR: Progressor;
            case AGGRESSOR: Aggressor;
            case DEFENSOR: Defensor;
            case LIBERATOR: Liberator;
            case DOMINATOR: Dominator;
            case INTELLECTOR: Intellector;
        }
    }
}
