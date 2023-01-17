package net.shared.board;

import net.shared.PieceColor.opposite;
import net.shared.board.MovementPattern;

using Lambda;

class Rules 
{
    private static function getAllowedMovements(hex:Hex, ?excludeDefensorCastling:Bool = false):Map<MovementPattern, Array<Direction>>
    {
        var piece:Null<PieceData> = hex.piece();

        if (piece == null)
            return [];

        return switch piece.type 
        {
            case Progressor: [SimpleJump(1) => Direction.forwardLateral(piece.color)];
            case Aggressor: [NormalSlide => Direction.allRadial()];
            case Dominator: [NormalSlide => Direction.allLateral()];
            case Liberator: [NonCapturingJump(1) => Direction.allLateral(), SimpleJump(2) => Direction.allLateral()];
            case Defensor: excludeDefensorCastling? [SimpleJump(1) => Direction.allLateral()] : [SimpleJump(1) => Direction.allLateral(), Swap(Intellector) => Direction.allLateral()];
            case Intellector: [NonCapturingJump(1) => Direction.allLateral(), Swap(Defensor) => Direction.allLateral()];
        }
    }
    
    public static function getPossibleDestinations(departure:HexCoords, pieceArrangement:PieceArrangement, ?excludeDefensorCastling:Bool = false):Array<HexCoords> 
    {
        var possibleDestinations:Array<HexCoords> = [];

        var departureHex:Hex = pieceArrangement.get(departure);
        var allowedMovements:Map<MovementPattern, Array<Direction>> = getAllowedMovements(departureHex);

        for (pattern => directions in allowedMovements)
            for (dir in directions)
                switch pattern 
                {
                    case SimpleJump(distance):
                        var destination:HexCoords = departure.step(dir, distance);
                        if (destination.isValid() && pieceArrangement.get(destination).color() != departureHex.color()) //Empty or occupied by enemy
                            possibleDestinations.push(destination);
                    case NonCapturingJump(distance):
                        var destination:HexCoords = departure.step(dir, distance);
                        if (destination.isValid() && pieceArrangement.get(destination).match(Empty))
                            possibleDestinations.push(destination);
                    case NormalSlide:
                        var destination:HexCoords = departure;
                        var proceed:Bool = true;
                        while (proceed)
                        {
                            destination = destination.step(dir);

                            if (!destination.isValid())
                                break;

                            var hexColor:Null<PieceColor> = pieceArrangement.get(destination).color();
                            if (hexColor == departureHex.color())
                                proceed = false;
                            else if (hexColor == null)
                                possibleDestinations.push(destination);
                            else
                            {
                                proceed = false;
                                possibleDestinations.push(destination);
                            }
                        }
                    case Swap(partner):
                        var destination:HexCoords = departure.step(dir);
                        if (!destination.isValid())
                            continue;

                        var destinationHex:Hex = pieceArrangement.get(destination);
                        var desiredHex:Hex = Occupied(new PieceData(partner, departureHex.color()));
                        if (destinationHex.equals(desiredHex))
                            possibleDestinations.push(destination);

                }

        return possibleDestinations;
    }
    
    public static function getPossiblePremoveDestinations(departure:HexCoords, piece:PieceData):Array<HexCoords>  
    {
        var possibleDestinations:Array<HexCoords> = [];

        var allowedMovements:Map<MovementPattern, Array<Direction>> = getAllowedMovements(Occupied(piece));

        for (pattern => directions in allowedMovements)
            for (dir in directions)
                switch pattern 
                {
                    case SimpleJump(distance), NonCapturingJump(distance):
                        var destination:HexCoords = departure.step(dir, distance);
                        if (destination.isValid())
                            possibleDestinations.push(destination);
                    case NormalSlide:
                        var destination:HexCoords = departure.step(dir);
                        while (destination.isValid())
                        {
                            possibleDestinations.push(destination);
                            destination = destination.step(dir);
                        }
                    case Swap(_):
                        var destination:HexCoords = departure.step(dir);
                        if (destination.isValid())
                            possibleDestinations.push(destination);
                }

        return possibleDestinations;
    }

    public static function isMovementPossible(from:HexCoords, to:HexCoords, pieceArrangement:PieceArrangement):Bool
    {
        var movingPiece = pieceArrangement.get(from).piece();
        if (movingPiece == null)
            return false;
        else
            return getPossibleDestinations(from, pieceArrangement).exists(x -> x.equals(to));
    }

    public static function isPossible(ply:RawPly, situation:Situation):Bool
    {
        var movingPiece = situation.pieces.get(ply.from).piece();

        if (movingPiece == null || movingPiece.color != situation.turnColor)
            return false;
        else if (ply.morphInto != null && movingPiece.type == Progressor && ply.to.isFinal(movingPiece.color))
        {
            var impossiblePromotionType:Bool = ply.morphInto == Intellector || ply.morphInto == Progressor;

            if (impossiblePromotionType)
                return false;
        }
        else if (ply.morphInto != null)
        {
            var intChameleon:Bool = movingPiece.type == Intellector;
            var noAura:Bool = situation.intellectorCoords(movingPiece.color) == null || !situation.intellectorCoords(movingPiece.color).isLaterallyNear(ply.from);
            var wrongChameleonType:Bool = ply.morphInto != situation.pieces.get(ply.to).type();

            if (intChameleon || noAura || wrongChameleonType)
                return false;
        }

        return getPossibleDestinations(ply.from, situation.pieces).exists(x -> x.equals(ply.to));
    }

    public static function isPremovePossible(from:HexCoords, to:HexCoords, pieceArrangement:PieceArrangement):Bool 
    {
        var movingPiece = pieceArrangement.get(from).piece();
        if (movingPiece == null)
            return false;
        else
            return getPossiblePremoveDestinations(from, movingPiece).exists(x -> x.equals(to));
    }

    public static function possiblePromotionTypes():Array<PieceType>
    {
        return [Liberator, Aggressor, Defensor, Dominator];
    }

    public static function possiblePlys(situation:Situation):Array<RawPly> 
    {
        var plys:Array<RawPly> = [];
        var allPieces = situation.collectPieces();

        for (coords => piece in allPieces)
            if (piece.color == situation.turnColor)
                for (destination in getPossibleDestinations(coords, situation.pieces, true))
                    if (piece.type == Progressor && destination.isFinal(piece.color))
                        for (newType in possiblePromotionTypes())
                            plys.push(RawPly.construct(coords, destination, newType));
                    else 
                    {
                        var pieceOnDestination:Null<PieceData> = situation.get(destination).piece();
                        var isCapture:Bool = pieceOnDestination != null && pieceOnDestination.color != piece.color;
                        var isAffectedByAura:Bool = situation.intellectorCoords(piece.color).isLaterallyNear(coords);

                        plys.push(RawPly.construct(coords, destination, null));
                        if (piece.type != Intellector && isCapture && isAffectedByAura)
                            plys.push(RawPly.construct(coords, destination, pieceOnDestination.type));
                    }

        return plys;
    }
}