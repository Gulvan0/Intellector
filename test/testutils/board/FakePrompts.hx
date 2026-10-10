package testutils.board;

import client.ui.common.board.move_prompt.MovePrompts;
import client.ui.common.board.move_prompt.OpenPrompt;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceKind;

enum FakePromptKind
{
    Promotion;
    CaptureMorph(capturedKind:PieceKind);
    PremoveChameleon(movingKind:PieceKind);
}

class FakePrompt implements OpenPrompt
{
    public final kind:FakePromptKind;
    public final anchor:HexCoords;
    public var closed(default, null):Bool = false;

    public function new(kind:FakePromptKind, anchor:HexCoords)
    {
        this.kind = kind;
        this.anchor = anchor;
    }

    public function close():Void
    {
        closed = true;
    }
}

/** Opens `FakePrompt`s that the test answers, closing them before calling back like `MovePrompt` **/
class FakePrompts implements MovePrompts
{
    /** The prompt opened last, closed or not **/
    public var last(default, null):Null<FakePrompt> = null;

    private var onPieceChosen:Null<PieceKind->Void> = null;
    private var onMorphDecided:Null<Bool->Void> = null;
    private var onCancelled:Null<Void->Void> = null;

    public function new() {}

    public function promotion(anchor:HexCoords, color:PieceColor, onChosen:PieceKind->Void, onCancelled:Void->Void):OpenPrompt
    {
        return open(Promotion, anchor, onChosen, null, onCancelled);
    }

    public function captureMorph(anchor:HexCoords, capturingKind:PieceKind, capturingColor:PieceColor, capturedKind:PieceKind, onDecided:Bool->Void, onCancelled:Void->Void):OpenPrompt
    {
        return open(CaptureMorph(capturedKind), anchor, null, onDecided, onCancelled);
    }

    public function premoveChameleon(anchor:HexCoords, movingKind:PieceKind, color:PieceColor, onChosen:PieceKind->Void, onCancelled:Void->Void):OpenPrompt
    {
        return open(PremoveChameleon(movingKind), anchor, onChosen, null, onCancelled);
    }

    /** Whether a prompt is on screen **/
    public function isOpen():Bool
    {
        return last != null && !last.closed;
    }

    public function choose(kind:PieceKind):Void
    {
        last.close();
        onPieceChosen(kind);
    }

    public function decide(morph:Bool):Void
    {
        last.close();
        onMorphDecided(morph);
    }

    public function cancel():Void
    {
        last.close();
        onCancelled();
    }

    private function open(kind:FakePromptKind, anchor:HexCoords, onPieceChosen:Null<PieceKind->Void>, onMorphDecided:Null<Bool->Void>, onCancelled:Void->Void):FakePrompt
    {
        last = new FakePrompt(kind, anchor);
        this.onPieceChosen = onPieceChosen;
        this.onMorphDecided = onMorphDecided;
        this.onCancelled = onCancelled;
        return last;
    }
}
