package gameboard;

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

    public function highlightMove(hexesCoords:Array<IntPoint>) 
    {
        for (hex in lastMoveSelectedHexes)
            hex.hideLayer(LastMove);

        lastMoveSelectedHexes = [for (coords in hexesCoords) getHex(hexesCoords)];

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

    public function removeMarkers(from:IntPoint) 
    {
        for (destination in Rules.possibleFields(from, shownSituation.get))
            getHex(destination).removeMarkers();
    }

    private function onClick(e)
    {
        for (index in redSelectedHexIndices)
            hexagons[index].hideLayer(RMB);
        for (arrow in drawnArrows)
            removeChild(arrow);

        drawnArrows = [];
        redSelectedHexIndices = [];
    }

    private function onRightPress(e)
    {
        arrowStartLocation = posToIndexes(e.stageX - x, e.stageY - y);
    }

    private function onRightRelease(e)
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
        var fromPos:Point = hexCoords(from.i, from.j);
        var toPos:Point = hexCoords(to.i, to.j);

        var thickness:Float = hexSideLength / 6;
        var lrLength:Float = hexSideLength / 2;
        var dr = fromPos.subtract(toPos);
        var rotated1 = new Point(Math.sqrt(3)/2 * dr.x + 1/2 * dr.y, -1/2 * dr.x + Math.sqrt(3)/2 * dr.y);
        var rotated2 = new Point(Math.sqrt(3)/2 * dr.x - 1/2 * dr.y, 1/2 * dr.x + Math.sqrt(3)/2 * dr.y);
        rotated1.normalize(lrLength);
        rotated2.normalize(lrLength);
        var branch1 = toPos.add(rotated1);
        var branch2 = toPos.add(rotated2);

        var arrow:Sprite = new Sprite();
        arrow.graphics.lineStyle(thickness, Colors.arrow, 0.7, null, null, CapsStyle.SQUARE, JointStyle.MITER);
        arrow.graphics.moveTo(fromPos.x, fromPos.y);
        arrow.graphics.lineTo(toPos.x, toPos.y);
        arrow.graphics.lineTo(branch1.x, branch1.y);
        arrow.graphics.moveTo(toPos.x, toPos.y);
        arrow.graphics.lineTo(branch2.x, branch2.y);
        
        var code = '${from.i}${from.j}${to.i}${to.j}';
        drawnArrows.set(code, arrow);
        addChild(arrow);
    }

    public function new(situation:Situation, orientationColor:PieceColor = White, hexSideLength:Float = 40, suppressMarkup:Bool = false) 
    {
        super(situation, orientationColor, hexSideLength, suppressMarkup);

        addEventListener(Event.ADDED_TO_STAGE, onAdded);
    }
}