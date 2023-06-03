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
    
    public static function getPossibleDestinations(departure:HexCoords, hexRetriever:HexCoords->Hex, ?excludeDefensorCastling:Bool = false):Array<HexCoords> 
    {
        var possibleDestinations:Array<HexCoords> = [];

        var departureHex:Hex = hexRetriever(departure);
        var allowedMovements:Map<MovementPattern, Array<Direction>> = getAllowedMovements(departureHex);

        for (pattern => directions in allowedMovements)
            for (dir in directions)
                switch pattern 
                {
                    case SimpleJump(distance):
                        var destination:HexCoords = departure.step(dir, distance);
                        if (destination.isValid() && hexRetriever(destination).color() != departureHex.color()) //Empty or occupied by enemy
                            possibleDestinations.push(destination);
                    case NonCapturingJump(distance):
                        var destination:HexCoords = departure.step(dir, distance);
                        if (destination.isValid() && hexRetriever(destination).match(Empty))
                            possibleDestinations.push(destination);
                    case NormalSlide:
                        var destination:HexCoords = departure;
                        var proceed:Bool = true;
                        while (proceed)
                        {
                            destination = destination.step(dir);

                            if (!destination.isValid())
                                break;

                            var hexColor:Null<PieceColor> = hexRetriever(destination).color();
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

                        var destinationHex:Hex = hexRetriever(destination);
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
            return getPossibleDestinations(from, pieceArrangement.get).exists(x -> x.equals(to));
    }

    public static function isPossible(ply:RawPly, situation:Situation):Bool
    {
        var movingPiece = situation.pieces.get(ply.from).piece();

        if (movingPiece == null || movingPiece.color != situation.turnColor)
            return false;
        else if (isPromotionAvailable(ply.from, ply.to, situation))
        {
            var validPromotionType:Bool = ply.morphInto != null && possiblePromotionTypes().contains(ply.morphInto);

            if (!validPromotionType)
                return false;
        }
        else if (ply.morphInto != null)
        {
            var chameleonNotPossible:Bool = !isChameleonAvailable(ply.from, ply.to, situation);
            var fakedChameleon:Bool = ply.morphInto != situation.get(ply.to).type();

            if (chameleonNotPossible || fakedChameleon)
                return false;
        }

        return getPossibleDestinations(ply.from, situation.pieces.get).exists(x -> x.equals(ply.to));
    }

    public static function isPremovePossible(from:HexCoords, to:HexCoords, pieceArrangement:PieceArrangement):Bool 
    {
        var movingPiece = pieceArrangement.get(from).piece();
        if (movingPiece == null)
            return false;
        else
            return getPossiblePremoveDestinations(from, movingPiece).exists(x -> x.equals(to));
    }

    public static function isPromotionAvailable(from:HexCoords, to:HexCoords, situation:Situation):Bool
    {
        var movingPiece:Null<PieceData> = situation.get(from).piece();

        if (movingPiece == null)
            return false;

        return movingPiece.type == Progressor && to.isFinal(movingPiece.color);
    }

    public static function isChameleonAvailable(from:HexCoords, to:HexCoords, situation:Situation):Bool
    {
        var movingPiece:Null<PieceData> = situation.get(from).piece();
        var pieceOnDestination:Null<PieceData> = situation.get(to).piece();

        if (movingPiece == null)
            return false;

        var pieceCanChameleon:Bool = movingPiece.type != Intellector && movingPiece.type != Progressor;
        var isCapture:Bool = pieceOnDestination != null && pieceOnDestination.color != movingPiece.color;
        var isAffectedByAura:Bool = situation.intellectorCoords(movingPiece.color).isLaterallyNear(from);
        var pieceTypeWillChange:Bool = pieceOnDestination.type != movingPiece.type;

        return pieceCanChameleon && isCapture && isAffectedByAura && pieceTypeWillChange;
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
                for (destination in getPossibleDestinations(coords, situation.pieces.get, true))
                    if (isPromotionAvailable(coords, destination, situation))
                        for (newType in possiblePromotionTypes())
                            plys.push(RawPly.construct(coords, destination, newType));
                    else 
                    {
                        plys.push(RawPly.construct(coords, destination, null));
                        if (isChameleonAvailable(coords, destination, situation))
                            plys.push(RawPly.chameleon(coords, destination, situation));
                    }

        return plys;
    }
}