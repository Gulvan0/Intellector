package gameboard;

import gfx.Dialogs;
import haxe.ui.core.Component;
import gameboard.components.Hexagon;
import gameboard.util.HexagonSelectionState;
import net.shared.board.Rules;
import gameboard.util.Marking;
import gameboard.components.graphics.ArrowCanvas;
import haxe.ui.events.UIEvent;
import haxe.ui.core.Screen;
import haxe.ui.events.MouseEvent;
import net.shared.board.Situation;
import net.shared.PieceColor;
import haxe.ui.geom.Point;
import net.shared.board.HexCoords;
import haxe.ui.components.Canvas;
import haxe.ui.containers.Absolute;

using Lambda;

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

    private var arrowLayer:Absolute;
    private var drawnArrows:Map<String, ArrowCanvas> = [];
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
            arrow.redraw(dimensions, fromPos, toPos);
        }
    }

    public override function setOrientation(val:PieceColor) 
    {
        super.setOrientation(val);
        updateAllArrows();
    }

    public override function resize(?e)
    {
        super.resize(e);
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
                getHex(destination).addCircle();
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
            arrowLayer.removeComponent(arrow);

        drawnArrows = [];
    }

    private function toLocalCoords(screenX:Float, screenY:Float, ?relativeTo:Component):Point
    {
        if (relativeTo == null)
            relativeTo = this;
        return new Point(screenX - relativeTo.screenLeft, screenY - relativeTo.screenTop);
    }

    private function clickSelectableHandler(e:MouseEvent)
    {
        if (suppressRMBHandler || Dialogs.getQueue().hasActiveDialog())
            return;

        removeArrowsAndSelections();
    }

    private function rightPressSelectableHandler(e:MouseEvent)
    {
        if (suppressRMBHandler || Dialogs.getQueue().hasActiveDialog()) 
            return;

        arrowStartLocation = posToIndexes(toLocalCoords(e.screenX, e.screenY));
    }

    private function rightReleaseSelectableHandler(e:MouseEvent)
    {
        if (suppressRMBHandler)
            return;

        var arrowEndLocation = posToIndexes(toLocalCoords(e.screenX, e.screenY));

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
                    arrowLayer.removeComponent(drawnArrows[code]);
                    drawnArrows.remove(code);
                }
                else 
                    drawArrow(arrowStartLocation, arrowEndLocation);
            }

        arrowStartLocation = null;
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

        if (!drawnArrows.exists(code))
        {
            var arrow:ArrowCanvas = new ArrowCanvas(dimensions, fromPos, toPos);
            drawnArrows.set(code, arrow);
            arrowLayer.addComponent(arrow);
        }
    }

    @:bind(this, UIEvent.SHOWN)
    private function onAdded(e)
    {
        registerEvent(MouseEvent.CLICK, clickSelectableHandler);
        Screen.instance.registerEvent(MouseEvent.RIGHT_MOUSE_DOWN, rightPressSelectableHandler);
        Screen.instance.registerEvent(MouseEvent.RIGHT_MOUSE_UP, rightReleaseSelectableHandler);
    }

    @:bind(this, UIEvent.HIDDEN)
    private function onRemoved(e)
    {
        unregisterEvent(MouseEvent.CLICK, clickSelectableHandler);
        Screen.instance.unregisterEvent(MouseEvent.RIGHT_MOUSE_DOWN, rightPressSelectableHandler);
        Screen.instance.unregisterEvent(MouseEvent.RIGHT_MOUSE_UP, rightReleaseSelectableHandler);
    }

    //TODO: Signature updated
    public function new(initialSit:Situation, arrowMode:SelectionMode, hexMode:SelectionMode, orientation:PieceColor = White, ?marks:Marking, ?initialW:Float, ?initialH:Float) 
    {
        super(initialSit, orientation, marks, initialW, initialH);
        this.arrowMode = arrowMode;
        this.hexMode = hexMode;

        arrowLayer = new Absolute();
        addComponent(arrowLayer);
    }
}