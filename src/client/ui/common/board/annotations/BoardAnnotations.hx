package client.ui.common.board.annotations;

import client.datatypes.AnnotationHexStyle;
import client.ui.common.board.AnnotationColor;
import client.ui.common.board.BoardView;
import client.ui.common.board.HexTints;
import client.ui.common.board.PositionChangeCause;
import intellectorboard.primitives.hex.HexCoords;
import morestd.Detachable;

using Lambda;

/**
    The user's annotations on one board: at most one per hex and one arrow per ordered pair of hexes.
    Drawing one that's already there, in any color, removes it. Hex annotations show as rings or
    `AnnotationFill` tints, per the hex style.
**/
class BoardAnnotations
{
    private final board:BoardView;
    private final canvas:AnnotationCanvas;
    private final tints:HexTints;
    private final positionHandle:Detachable;

    private var hexAnnotations:Array<HexAnnotation> = [];
    private var arrows:Array<ArrowAnnotation> = [];

    private var hexStyle:AnnotationHexStyle;
    private var clearsOnPositionChange:Bool;

    public function new(board:BoardView, canvas:AnnotationCanvas, tints:HexTints, hexStyle:AnnotationHexStyle, clearsOnPositionChange:Bool)
    {
        this.board = board;
        this.canvas = canvas;
        this.tints = tints;
        this.hexStyle = hexStyle;
        this.clearsOnPositionChange = clearsOnPositionChange;

        positionHandle = board.onPositionChanged.subscribe(onPositionChanged);
    }

    public function dispose():Void
    {
        positionHandle.detach();
        clear();
    }

    public function apply(intent:AnnotationIntent):Void
    {
        switch intent
        {
            case AnnotateHex(hex, color):
                toggleHex(hex, color);
            case AnnotateArrow(from, to, color):
                toggleArrow(from, to, color);
            case ClearAnnotations:
                clear();
        }
    }

    /** Removes the annotation on `hex` if there is one, otherwise adds one in `color` **/
    public function toggleHex(hex:HexCoords, color:AnnotationColor):Void
    {
        var existing:Null<HexAnnotation> = hexAnnotations.find(annotation -> annotation.hex.equals(hex));
        if (existing != null)
            hexAnnotations.remove(existing);
        else
            hexAnnotations.push({hex: hex, color: color});
        render();
    }

    /** Removes the arrow from `from` to `to` if there is one, otherwise adds one in `color` **/
    public function toggleArrow(from:HexCoords, to:HexCoords, color:AnnotationColor):Void
    {
        var existing:Null<ArrowAnnotation> = arrows.find(arrow -> arrow.from.equals(from) && arrow.to.equals(to));
        if (existing != null)
            arrows.remove(existing);
        else
            arrows.push({from: from, to: to, color: color});
        render();
    }

    public function clear():Void
    {
        if (hexAnnotations.length == 0 && arrows.length == 0)
            return;

        hexAnnotations = [];
        arrows = [];
        render();
    }

    public function setHexStyle(hexStyle:AnnotationHexStyle):Void
    {
        this.hexStyle = hexStyle;
        render();
    }

    /** Whether any change of the shown position clears the annotations **/
    public function setClearsOnPositionChange(clearsOnPositionChange:Bool):Void
    {
        this.clearsOnPositionChange = clearsOnPositionChange;
    }

    private function onPositionChanged(_:PositionChangeCause):Void
    {
        if (clearsOnPositionChange)
            clear();
    }

    private function render():Void
    {
        var asTints:Bool = hexStyle == TINT;

        canvas.setAnnotations(asTints ? [] : hexAnnotations.copy(), arrows.copy());

        for (color in AnnotationColor.createAll())
        {
            var hexes:Array<HexCoords> = asTints ? [for (annotation in hexAnnotations) if (annotation.color == color) annotation.hex] : [];
            tints.set(AnnotationFill(color), hexes);
        }
    }
}
