package gameboard;

import openfl.display.Graphics;
import gfx.utils.Colors;
import openfl.display.JointStyle;
import openfl.display.CapsStyle;
import openfl.geom.Point;
import openfl.events.Event;
import struct.PieceColor;
import struct.Situation;
import openfl.display.Sprite;
import struct.IntPoint;
import openfl.events.MouseEvent;
using Lambda;

/**A basic Board with automatic RMB selection handling plus option to highlight last moves and add hex markers**/
class SelectableBoard extends Board
{
    private var drawnArrows:Map<String, Sprite> = [];
    private var arrowStartLocation:Null<IntPoint>;
    private var redSelectedHexIndices:Array<Int> = [];
    private var lastMoveSelectedHexes:Array<Hexagon> = [];

    public override function setOrientation(val:PieceColor) 
    {
        super.setOrientation(val);
        for (code => arrow in drawnArrows.keyValueIterator()) //TODO: Think about making a separate class Arrow. BranchingTab's arrows should also be instances of this class
        {
            var from:IntPoint = new IntPoint(Std.parseInt(code.charAt(0)), Std.parseInt(code.charAt(1)));
            var to:IntPoint = new IntPoint(Std.parseInt(code.charAt(2)), Std.parseInt(code.charAt(3)));
            var fromPos:Point = hexCoords(from);
            var toPos:Point = hexCoords(to);
            redrawArrow(arrow.graphics, fromPos, toPos);
        }
    }

    public function highlightMove(hexesCoords:Array<IntPoint>) 
    {
        for (hex in lastMoveSelectedHexes)
            hex.hideLayer(LastMove);

        lastMoveSelectedHexes = [for (coords in hexesCoords) getHex(coords)];

        for (hex in lastMoveSelectedHexes)
            hex.showLayer(LastMove);
    }

    public function addMarkers(from:IntPoint) 
    {
        for (destination in Rules.possibleFields(from, shownSituation.get))
            if (shownSituation.get(destination).isEmpty())
                getHex(destination).addDot();
            else
                getHex(destination).addRound();
    }

    //* Doesn't check whether a marker belongs to a different departure IntPoint since there is normally no more than 1 departure present
    public function removeMarkers(from:IntPoint) 
    {
        for (destination in Rules.possibleFields(from, shownSituation.get))
            getHex(destination).removeMarkers();
    }

    public function removeArrowsAndSelections()
    {
        for (index in redSelectedHexIndices)
            hexagons[index].hideLayer(RMB);
        for (arrow in drawnArrows)
            removeChild(arrow);

        drawnArrows = [];
        redSelectedHexIndices = [];
    }

    private function onClick(e:MouseEvent)
    {
        removeArrowsAndSelections();
    }

    private function onRightPress(e:MouseEvent)
    {
        arrowStartLocation = posToIndexes(e.stageX - x, e.stageY - y);
    }

    private function onRightRelease(e:MouseEvent)
    {
        var arrowEndLocation = posToIndexes(e.stageX - x, e.stageY - y);
        if (arrowStartLocation != null && arrowEndLocation != null)
            if (arrowStartLocation.equals(arrowEndLocation))
            {
                var hexToSelect = getHex(arrowStartLocation);
                var hexScalarIndex = arrowStartLocation.toScalar();

                if (redSelectedHexIndices.has(hexScalarIndex))
                {
                    hexToSelect.hideLayer(RMB);
                    redSelectedHexIndices.remove(hexScalarIndex);
                }
                else 
                {
                    hexToSelect.showLayer(RMB);
                    redSelectedHexIndices.push(hexScalarIndex);
                }
            }
            else
            {
                var code = '${arrowStartLocation.i}${arrowStartLocation.j}${arrowEndLocation.i}${arrowEndLocation.j}';
                if (drawnArrows.exists(code))
                {
                    removeChild(drawnArrows[code]);
                    drawnArrows.remove(code);
                }
                else 
                    drawArrow(arrowStartLocation, arrowEndLocation);
            }

        arrowStartLocation = null;
    }

    private function onAdded(e)
    {
        removeEventListener(Event.ADDED_TO_STAGE, onAdded);
        stage.addEventListener(MouseEvent.CLICK, onClick);
        stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightPress);
        stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightRelease);
        addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
    }

    private function onRemoved(e)
    {
        removeEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
        stage.removeEventListener(MouseEvent.CLICK, onClick);
        stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightPress);
        stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightRelease);
    }

    public function drawArrow(from:IntPoint, to:IntPoint)
    {
        var fromPos:Point = hexCoords(from);
        var toPos:Point = hexCoords(to);

        var arrow:Sprite = new Sprite();
        redrawArrow(arrow.graphics, fromPos, toPos);
        
        var code = '${from.i}${from.j}${to.i}${to.j}';
        drawnArrows.set(code, arrow);
        addChild(arrow);
    }

    private function redrawArrow(graphics:Graphics, fromPos:Point, toPos:Point) 
    {
        var thickness:Float = hexSideLength / 6;
        var lrLength:Float = hexSideLength / 2;
        var dr = fromPos.subtract(toPos);
        var rotated1 = new Point(Math.sqrt(3)/2 * dr.x + 1/2 * dr.y, -1/2 * dr.x + Math.sqrt(3)/2 * dr.y);
        var rotated2 = new Point(Math.sqrt(3)/2 * dr.x - 1/2 * dr.y, 1/2 * dr.x + Math.sqrt(3)/2 * dr.y);
        rotated1.normalize(lrLength);
        rotated2.normalize(lrLength);
        var branch1 = toPos.add(rotated1);
        var branch2 = toPos.add(rotated2);

        graphics.clear();
        graphics.lineStyle(thickness, Colors.arrow, 0.7, null, null, CapsStyle.SQUARE, JointStyle.MITER);
        graphics.moveTo(fromPos.x, fromPos.y);
        graphics.lineTo(toPos.x, toPos.y);
        graphics.lineTo(branch1.x, branch1.y);
        graphics.moveTo(toPos.x, toPos.y);
        graphics.lineTo(branch2.x, branch2.y);
    }

    public function new(situation:Situation, orientationColor:PieceColor = White, hexSideLength:Float = 40, suppressMarkup:Bool = false) 
    {
        super(situation, orientationColor, hexSideLength, suppressMarkup);

        addEventListener(Event.ADDED_TO_STAGE, onAdded);
    }
}