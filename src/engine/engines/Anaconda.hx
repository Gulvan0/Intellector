package engine.engines;

import net.shared.board.RawPly;
import net.shared.board.Hex;
import net.shared.board.PieceData;
import net.shared.board.HexCoords;
import net.shared.board.Situation;
import js.html.Worker;

private typedef AnacondaMove = {from:Int, to:Int, figure:Int};

class Anaconda extends Engine
{
    private var worker:Null<Worker>;

    public function evalutateByTime(situation:Situation, timeLimitSecs:Float, fullResultCallback:EvaluationResult->Void, ?partialResultCallback:EvaluationResult->Void)
    {
        interrupt();

        worker = new Worker('includes/position.js');
        worker.onmessage = e -> {
            var result:EvaluationResult = buildEvaluationResultByData(e.data, situation);
            if (e.data.completed)
            {
                worker = null;
                fullResultCallback(result);
            }
            else 
                partialResultCallback(result);
        }
        worker.postMessage({command: "bestMoveByTime", position: situationToAnacondaPosStr(situation), time: timeLimitSecs * 1000});
    }

    public function evalutateByDepth(situation:Situation, depth:Int, fullResultCallback:EvaluationResult->Void, ?partialResultCallback:EvaluationResult->Void)
    {
        interrupt();

        worker = new Worker('includes/position.js');
        worker.onmessage = e -> {
            var result:EvaluationResult = buildEvaluationResultByData(e.data, situation);
            if (e.data.completed)
            {
                worker = null;
                fullResultCallback(result);
            }
            else 
                partialResultCallback(result);
        }
        worker.postMessage({command: "bestMoveByLevel", position: situationToAnacondaPosStr(situation), level: depth});
    }

    public function interrupt()
    {
        if (worker != null)
            worker.terminate();
    }

    private function buildEvaluationResultByData(data:Dynamic, contextSituation:Situation):EvaluationResult
    {
        var sit:Situation = contextSituation.copy();
        var prevPly:RawPly = anacondaMoveToRawPly(data.move, sit);
        var mainLine:Array<RawPly> = [prevPly];

        for (move in cast(data.bestLine, Array<Dynamic>))
        {
            sit = sit.situationAfterRawPly(prevPly);
            prevPly = anacondaMoveToRawPly(move, sit);
            mainLine.push(prevPly);
        }

        return {
            mainLine: mainLine,
            score: data.mark,
            depth: data.depth
        };
    }

    private function hexCoordsToAnacondaIndex(hexCoords:HexCoords):Int 
    {
        var s = Math.floor(hexCoords.i / 2) * 13;
        if (hexCoords.i % 2 == 0)
            s += 6 - hexCoords.j;
        else
            s += 12 - hexCoords.j;
        return s;
    }

    private function anacondaIndexToHexCoords(index:Int):HexCoords
    {
        var quotient:Int = Math.floor(index / 13);
        var remainder:Int = index - quotient * 13;

        if (remainder > 6)
            return new HexCoords(2 * quotient + 1, 12 - remainder);
        else
            return new HexCoords(2 * quotient, 6 - remainder);
    }

    private function anacondaPieceCodeToData(code:Int):PieceData
    {
        return switch code 
        {
            case 0: new PieceData(Progressor, White);
            case 1: new PieceData(Progressor, Black);
            case 2: new PieceData(Dominator, White);
            case 3: new PieceData(Dominator, Black);
            case 4: new PieceData(Liberator, White);
            case 5: new PieceData(Liberator, Black);
            case 6: new PieceData(Aggressor, White);
            case 7: new PieceData(Aggressor, Black);
            case 8: new PieceData(Defensor, White);
            case 9: new PieceData(Defensor, Black);
            case 10: new PieceData(Intellector, White);
            case 11: new PieceData(Intellector, Black);
            default: throw 'Unexpected piece code: $code';
        }
    }

    private function pieceDataToAnacondaStr(pieceData:PieceData):String
    {
        return switch [pieceData.type, pieceData.color]
        {
            case [Progressor, White]: "p";
            case [Aggressor, White]: "a";
            case [Dominator, White]: "m";
            case [Liberator, White]: "l";
            case [Defensor, White]: "d";
            case [Intellector, White]: "i";
            case [Progressor, Black]: "P";
            case [Aggressor, Black]: "A";
            case [Dominator, Black]: "M";
            case [Liberator, Black]: "L";
            case [Defensor, Black]: "D";
            case [Intellector, Black]: "I";
        } 
    }

    private function situationToAnacondaPosStr(situation:Situation):String 
    {
        var s = "";
        var i = 0;
        var j = 6;

        while (i < 9)
        {
            while (j >= 0)
            {
                switch situation.get(new HexCoords(i, j)) 
                {
                    case Empty:
                        s += "e";
                    case Occupied(piece):
                        s += pieceDataToAnacondaStr(piece);
                }
                j--;
            }

            i++;
            j = i % 2 == 0? 6 : 5;
        }

        var colorLetter:String = situation.turnColor == White? "w" : "b";
        return s + colorLetter;
    }

    private function anacondaMoveToRawPly(move:AnacondaMove, context:Situation):RawPly 
    {
        var from:HexCoords = anacondaIndexToHexCoords(move.from);
        var to:HexCoords = anacondaIndexToHexCoords(move.to);
        var morphInto:PieceData = anacondaPieceCodeToData(move.figure);
        var movingPiece:Null<PieceData> = context.get(from).piece();

        if (movingPiece == null || (movingPiece.type == morphInto.type && movingPiece.color == morphInto.color))
            return RawPly.construct(from, to, null);
        else
            return RawPly.construct(from, to, morphInto.type);
    }

    public function new() 
    {

    }
}