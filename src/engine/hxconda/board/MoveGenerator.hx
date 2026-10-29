package engine.hxconda.board;

import engine.hxconda.board.BoardGeometry.DIRECTION_COUNT;
import engine.hxconda.board.BoardGeometry.NO_SQUARE;
import js.lib.Math;

/**
    Pseudo-legal move generation for the side to move, in the order the original engine produced the moves.
**/
class MoveGenerator
{
    public static function generateMoves(board:Board):Array<Move>
    {
        var moves:Array<Move> = [];
        var pieces:Array<Piece> = board.pieces;

        for (half in 0...2)
        {
            var mask:Int = board.occupancyMask(board.turn, half);
            while (mask != 0)
            {
                var square:Int = lowestSquare(mask, half);
                mask &= mask - 1;
                var piece:Piece = pieces[square];

                switch piece
                {
                    case WhiteProgressor | BlackProgressor:
                        addProgressorMoves(moves, board, square, piece, true);
                    case WhiteDominator | BlackDominator:
                        addSlides(moves, board, square, piece, BoardGeometry.DOMINATOR_RAYS, true);
                    case WhiteAggressor | BlackAggressor:
                        addSlides(moves, board, square, piece, BoardGeometry.AGGRESSOR_RAYS, true);
                    case WhiteDefensor | BlackDefensor:
                        addSteps(moves, board, square, piece, BoardGeometry.NEIGHBOURS, true);
                    case WhiteLiberator | BlackLiberator:
                        addSteps(moves, board, square, piece, BoardGeometry.LIBERATOR_JUMPS, true);
                        addQuietSteps(moves, board, square, piece, BoardGeometry.NEIGHBOURS);
                    case WhiteIntellector | BlackIntellector:
                        addIntellectorMoves(moves, board, square, piece);
                    default:
                }
            }
        }

        return moves;
    }

    /** Captures only; intellectors never capture **/
    public static function generateCaptures(board:Board):Array<Move>
    {
        var moves:Array<Move> = [];
        var pieces:Array<Piece> = board.pieces;

        for (half in 0...2)
        {
            var mask:Int = board.occupancyMask(board.turn, half);
            while (mask != 0)
            {
                var square:Int = lowestSquare(mask, half);
                mask &= mask - 1;
                var piece:Piece = pieces[square];

                switch piece
                {
                    case WhiteProgressor | BlackProgressor:
                        addProgressorMoves(moves, board, square, piece, false);
                    case WhiteDominator | BlackDominator:
                        addSlides(moves, board, square, piece, BoardGeometry.DOMINATOR_RAYS, false);
                    case WhiteAggressor | BlackAggressor:
                        addSlides(moves, board, square, piece, BoardGeometry.AGGRESSOR_RAYS, false);
                    case WhiteDefensor | BlackDefensor:
                        addSteps(moves, board, square, piece, BoardGeometry.NEIGHBOURS, false);
                    case WhiteLiberator | BlackLiberator:
                        addSteps(moves, board, square, piece, BoardGeometry.LIBERATOR_JUMPS, false);
                    default:
                }
            }
        }

        return moves;
    }

    /** The lowest square in a nonzero `Board.occupancyMask` of `half` **/
    private static inline function lowestSquare(mask:Int, half:Int):Int
    {
        return (half << 5) | (31 - Math.clz32(mask & -mask));
    }

    private static inline function addSlides(moves:Array<Move>, board:Board, square:Int, piece:Piece, rays:SquareLists, includeQuiet:Bool):Void
    {
        var pieces:Array<Piece> = board.pieces;
        var squares:Array<Int> = rays.squares;

        for (direction in 0...DIRECTION_COUNT)
        {
            var ray:Int = square * DIRECTION_COUNT + direction;
            var k:Int = rays.start(ray);
            var end:Int = rays.end(ray);

            while (k < end && pieces[squares[k]] == Empty)
            {
                if (includeQuiet)
                    moves.push(new Move(square, squares[k], piece));
                k++;
            }

            if (k < end && pieces[squares[k]].color() != piece.color())
                addCapture(moves, board, square, squares[k], piece);
        }
    }

    private static inline function addSteps(moves:Array<Move>, board:Board, square:Int, piece:Piece, steps:SquareLists, includeQuiet:Bool):Void
    {
        var pieces:Array<Piece> = board.pieces;
        var squares:Array<Int> = steps.squares;

        for (k in steps.start(square)...steps.end(square))
        {
            var target:Int = squares[k];
            var targetPiece:Piece = pieces[target];
            if (targetPiece == Empty)
            {
                if (includeQuiet)
                    moves.push(new Move(square, target, piece));
            }
            else if (targetPiece.color() != piece.color())
                addCapture(moves, board, square, target, piece);
        }
    }

    private static inline function addQuietSteps(moves:Array<Move>, board:Board, square:Int, piece:Piece, steps:SquareLists):Void
    {
        var pieces:Array<Piece> = board.pieces;
        var squares:Array<Int> = steps.squares;

        for (k in steps.start(square)...steps.end(square))
            if (pieces[squares[k]] == Empty)
                moves.push(new Move(square, squares[k], piece));
    }

    /** A capture, plus the capture that turns the piece into the captured kind if its intellector stands next to it **/
    private static inline function addCapture(moves:Array<Move>, board:Board, square:Int, target:Int, piece:Piece):Void
    {
        var targetPiece:Piece = board.pieces[target];
        moves.push(new Move(square, target, piece));

        if (targetPiece != piece.counterpart() && !targetPiece.isIntellector() && isNextToOwnIntellector(board, square, piece.color()))
            moves.push(new Move(square, target, targetPiece.counterpart()));
    }

    private static inline function isNextToOwnIntellector(board:Board, square:Int, color:PlayerColor):Bool
    {
        var intellectorSquare:Int = board.intellectorSquare(color);
        return intellectorSquare != NO_SQUARE && BoardGeometry.areAdjacent(square, intellectorSquare);
    }

    private static inline function addProgressorMoves(moves:Array<Move>, board:Board, square:Int, piece:Piece, includeQuiet:Bool):Void
    {
        var pieces:Array<Piece> = board.pieces;
        var color:PlayerColor = piece.color();
        var steps:SquareLists = color == White ? BoardGeometry.WHITE_PROGRESSOR_STEPS : BoardGeometry.BLACK_PROGRESSOR_STEPS;
        var squares:Array<Int> = steps.squares;

        for (k in steps.start(square)...steps.end(square))
        {
            var target:Int = squares[k];
            var targetPiece:Piece = pieces[target];
            var isAllowed:Bool = targetPiece == Empty ? includeQuiet : targetPiece.color() != color;
            if (!isAllowed)
                continue;

            if (BoardGeometry.isFinalSquare(target, color))
            {
                moves.push(new Move(square, target, WhiteDominator.ofColor(color)));
                moves.push(new Move(square, target, WhiteLiberator.ofColor(color)));
                moves.push(new Move(square, target, WhiteAggressor.ofColor(color)));
                moves.push(new Move(square, target, WhiteDefensor.ofColor(color)));
            }
            else
                moves.push(new Move(square, target, piece));
        }
    }

    private static inline function addIntellectorMoves(moves:Array<Move>, board:Board, square:Int, piece:Piece):Void
    {
        var pieces:Array<Piece> = board.pieces;
        var squares:Array<Int> = BoardGeometry.NEIGHBOURS.squares;
        var ownDefensor:Piece = WhiteDefensor.ofColor(piece.color());

        for (k in BoardGeometry.NEIGHBOURS.start(square)...BoardGeometry.NEIGHBOURS.end(square))
        {
            var targetPiece:Piece = pieces[squares[k]];
            if (targetPiece == Empty || targetPiece == ownDefensor)
                moves.push(new Move(square, squares[k], piece));
        }
    }
}
