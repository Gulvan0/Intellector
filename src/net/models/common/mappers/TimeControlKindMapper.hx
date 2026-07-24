package net.models.common.mappers;

class TimeControlKindMapper
{
    public static function datatypeToDto(datatype:client.datatypes.TimeControlKind):net.models.common.TimeControlKind
    {
        return switch datatype {
            case Hyperbullet: HYPERBULLET;
            case Bullet: BULLET;
            case Blitz: BLITZ;
            case Rapid: RAPID;
            case Classic: CLASSIC;
            case Correspondence: CORRESPONDENCE;
        }
    }

    public static function dtoToDatatype(dto:net.models.common.TimeControlKind):client.datatypes.TimeControlKind
    {
        return switch dto {
            case HYPERBULLET: Hyperbullet;
            case BULLET: Bullet;
            case BLITZ: Blitz;
            case RAPID: Rapid;
            case CLASSIC: Classic;
            case CORRESPONDENCE: Correspondence;
        }
    }
}
