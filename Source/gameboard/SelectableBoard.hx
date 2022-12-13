package gameboard;

import net.shared.board.Rules;
import net.shared.board.HexCoords;
import net.shared.board.Situation;
import gfx.Dialogs;
import Preferences.Markup;
import openfl.display.Graphics;
import gfx.utils.Colors;
import openfl.display.JointStyle;
import openfl.display.CapsStyle;
import openfl.geom.Point;
import openfl.events.Event;
import net.shared.PieceColor;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
using Lambda;
using utils.Geometry;

enum SelectionMode
{
    Disabled;
    EnsureSingle;
    Free;
}

/**A basic Board with automatic RMB selection handling plus option to highlight last moves and add hex markers**/
class SelectableBoard extends Board
{
    public final arrowMode:SelectionMode;
    public final hexMode:SelectionMode;

    private var arrowLayer:Sprite;
    private var drawnArrows:Map<String, Sprite> = [];
    private var arrowStartLocation:Null<HexCoords>;
    private var redSelectedHexIndices:Array<Int> = [];
    private var lastMoveSelectedHexes:Array<Hexagon> = [];

    public var suppressRMBHandler:Bool = false;

    public function getAnyDrawnArrow():Null<{from:HexCoords, to:HexCoords}>
    {
        var keys = drawnArrows.keys();
        if (keys.hasNext())
            return decodeArrowKey(keys.next());
        else
            return null;
    }

    private function decodeArrowKey(code:String):{from:HexCoords, to:HexCoords}
    {
        var from:HexCoords = new HexCoords(Std.parseInt(code.charAt(0)), Std.parseInt(code.charAt(1)));
        var to:HexCoords = new HexCoords(Std.parseInt(code.charAt(2)), Std.parseInt(code.charAt(3)));
        return {from: from, to: to};
    }

    private function updateAllArrows()
    {
        for (code => arrow in drawnArrows.keyValueIterator())
        {
            var decoded = decodeArrowKey(code);
            var fromPos:Point = hexCoords(decoded.from);
            var toPos:Point = hexCoords(decoded.to);
            redrawArrow(arrow.graphics, fromPos, toPos);
        }
    }

    public override function setOrientation(val:PieceColor) 
    {
        super.setOrientation(val);
        updateAllArrows();
    }

    public override function resize(newHexSideLength:Float)
    {
        super.resize(newHexSideLength);
        updateAllArrows();
    }

    private function highlightMove(hexesCoords:Array<HexCoords>) 
    {
        for (hex in lastMoveSelectedHexes)
            hex.hideLayer(LastMove);

        lastMoveSelectedHexes = [for (coords in hexesCoords) getHex(coords)];

        for (hex in lastMoveSelectedHexes)
            hex.showLayer(LastMove);
    }

    public function addMarkers(from:HexCoords) 
    {
        var possibleDestinations = Rules.getPossibleDestinations(from, shownSituation.pieces);
        for (destination in possibleDestinations)
            if (shownSituation.get(destination).isEmpty())
                getHex(destination).addDot();
            else
                getHex(destination).addRound();
    }

    // Doesn't check whether a marker belongs to a different departure HexCoords since there is normally no more than 1 departure present
    public function removeMarkers(from:HexCoords) 
    {
        if (shownSituation.get(from).isEmpty())
            throw "Only non-empty hex may be passed as a removeMarkers() argument";
        
        var possibleDestinations = Rules.getPossibleDestinations(from, shownSituation.pieces);
        for (destination in possibleDestinations)
            getHex(destination).removeMarkers();
    }

    public function removeSingleMarker(location:HexCoords)
    {
        getHex(location).removeMarkers();
    }

    public function removeArrowsAndSelections()
    {
        removeArrows();
        removeRedHexSelections();
    }

    private function removeRedHexSelections()
    {
        for (index in redSelectedHexIndices)
            hexagons[index].hideLayer(RMB);
        
        redSelectedHexIndices = [];
    }

    private function removeArrows() 
    {
        for (arrow in drawnArrows)
            arrowLayer.removeChild(arrow);

        drawnArrows = [];
    }

    private function onClick(e:MouseEvent)
    {
        if (suppressRMBHandler || Dialogs.getQueue().hasActiveDialog())
            return;

        removeArrowsAndSelections();
    }

    private function onRightPress(e:MouseEvent)
    {
        if (suppressRMBHandler || Dialogs.getQueue().hasActiveDialog())
            return;

        arrowStartLocation = posToIndexes(e.stageX, e.stageY);
    }

    private function onRightRelease(e:MouseEvent)
    {
        if (suppressRMBHandler)
            return;

        var arrowEndLocation = posToIndexes(e.stageX, e.stageY);
        if (arrowStartLocation != null && arrowEndLocation != null)
            if (arrowStartLocation.equals(arrowEndLocation))
            {
                if (hexMode == Disabled)
                    return;

                toggleHexSelection(arrowStartLocation);
            }
            else
            {
                if (arrowMode == Disabled)
                    return;

                var code = '${arrowStartLocation.i}${arrowStartLocation.j}${arrowEndLocation.i}${arrowEndLocation.j}';
                if (drawnArrows.exists(code))
                {
                    arrowLayer.removeChild(drawnArrows[code]);
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
        if (hexMode == Disabled && arrowMode == Disabled)
            return;

        addEventListener(MouseEvent.CLICK, onClick);
        stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightPress);
        stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightRelease);
        addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
    }

    private function onRemoved(e)
    {
        removeEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
        removeEventListener(MouseEvent.CLICK, onClick);
        stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightPress);
        stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightRelease);
    }

    public function toggleHexSelection(location:HexCoords) 
    {
        var hexToSelect = getHex(location);
        var hexScalarIndex = location.toScalarCoord();

        if (redSelectedHexIndices.has(hexScalarIndex))
        {
            hexToSelect.hideLayer(RMB);
            redSelectedHexIndices.remove(hexScalarIndex);
        }
        else
        {
            if (hexMode == EnsureSingle)
                removeRedHexSelections();
            hexToSelect.showLayer(RMB);
            redSelectedHexIndices.push(hexScalarIndex);
        }
    }

    public function drawArrow(from:HexCoords, to:HexCoords)
    {
        if (arrowMode == EnsureSingle)
            removeArrows();

        var fromPos:Point = hexCoords(from);
        var toPos:Point = hexCoords(to);

        var code = '${from.i}${from.j}${to.i}${to.j}';

        if (drawnArrows.exists(code))
            redrawArrow(drawnArrows.get(code).graphics, fromPos, toPos);
        else 
        {
            var arrow:Sprite = new Sprite();
            redrawArrow(arrow.graphics, fromPos, toPos);
            drawnArrows.set(code, arrow);
            arrowLayer.addChild(arrow);
        }
    }

    private function redrawArrow(graphics:Graphics, fromCenter:Point, toCenter:Point) 
    {
        var trunkThickness:Float = 3 * hexSideLength / 8;
        var capTriangleSide:Float = 3 * hexSideLength / 4;
        var startRadius:Float = hexSideLength / 2; //hexSideLength is also a hex radius. We start drawing halfway to the bounding circle's border

        var direction:Point = toCenter.subtract(fromCenter);
        var orthogonalDirection:Point = direction.orthogonalCW();

        var capSupportVector:Point = direction.reversed().normalized(capTriangleSide);
        var sourceSupportVector:Point = orthogonalDirection.normalized(trunkThickness / 2);
        var jointSupportVector:Point = orthogonalDirection.normalized((capTriangleSide - trunkThickness) / 2);

        var capTopVertice:Point = toCenter;
        var capBottomCCWVertice:Point = capTopVertice.add(capSupportVector.rotated(-Math.PI / 6));
        var capBottomCWVertice:Point = capTopVertice.add(capSupportVector.rotated(Math.PI / 6));

        var trueSource:Point = fromCenter.add(direction.normalized(startRadius));
        var sourceCWVertice:Point = trueSource.add(sourceSupportVector);
        var sourceCCWVertice:Point = trueSource.subtract(sourceSupportVector);

        var jointCWVertice:Point = capBottomCWVertice.subtract(jointSupportVector);
        var jointCCWVertice:Point = capBottomCCWVertice.add(jointSupportVector);

        graphics.clear();
        graphics.beginFill(Colors.arrow, 0.75);
        graphics.moveTo(capTopVertice.x, capTopVertice.y);
        graphics.lineTo(capBottomCCWVertice.x, capBottomCCWVertice.y);
        graphics.lineTo(jointCCWVertice.x, jointCCWVertice.y);
        graphics.lineTo(sourceCCWVertice.x, sourceCCWVertice.y);
        graphics.lineTo(sourceCWVertice.x, sourceCWVertice.y);
        graphics.lineTo(jointCWVertice.x, jointCWVertice.y);
        graphics.lineTo(capBottomCWVertice.x, capBottomCWVertice.y);
        graphics.lineTo(capTopVertice.x, capTopVertice.y);
        graphics.endFill();
    }

    public function new(situation:Situation, arrowMode:SelectionMode, hexMode:SelectionMode, orientationColor:PieceColor = White, hexSideLength:Float = 40, enforcedMarkup:Null<Markup> = null) 
    {
        super(situation, orientationColor, hexSideLength, enforcedMarkup);
        this.arrowMode = arrowMode;
        this.hexMode = hexMode;

        arrowLayer = new Sprite();
        addChild(arrowLayer);
        
        addEventListener(Event.ADDED_TO_STAGE, onAdded);
    }
}