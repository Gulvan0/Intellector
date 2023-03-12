package gfx.live.board;

import gfx.live.board.util.HexSelectionMode;
import gfx.live.board.util.ArrowSelectionMode;
import net.shared.board.Hex;
import gfx.live.board.subcomponents.util.ArrowParams;
import haxe.ui.util.Color;
import gfx.Dialogs;
import haxe.ui.core.Component;
import gfx.live.board.subcomponents.Hexagon;
import gfx.live.board.util.HexagonLayer;
import net.shared.board.Rules;
import gfx.live.board.util.Marking;
import gfx.live.board.subcomponents.canvas.ArrowCanvas;
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

class SelectableBoard extends Board
{
    public final arrowMode:Map<Color, ArrowSelectionMode>;
    public final hexMode:Map<HexagonLayer, HexSelectionMode>;

    public var diminishmentOrder:Map<Color, Int>;
    public var arrowThicknessMultipliers:Map<String, Float> = [];

    private var arrowLayer:Absolute;

    private var drawnArrows:Map<String, ArrowCanvas> = [];

    public function toggleArrow(params:ArrowParams) 
    {
        var arrowHash:String = params.getHash();

        if (drawnArrows.exists(arrowHash))
        {
            arrowLayer.removeComponent(drawnArrows.get(arrowHash));
            diminishmentOrder[params.color] = 0;
            arrowThicknessMultipliers.remove(arrowHash);
            drawnArrows.remove(arrowHash);
            return;
        }

        var fromPos:Point = hexCoords(params.from);
        var toPos:Point = hexCoords(params.to);
        var thicknessMultiplier:Float = 1;

        switch arrowMode.get(params.color) 
        {
            case null | Disabled: 
                return;
            case EnsureSingle:
                removeAllArrows(params.color);
            case FreeDiminishing:
                thicknessMultiplier = Math.max(Math.pow(0.9, diminishmentOrder.get(params.color)), 0.1);
                diminishmentOrder[params.color]++;
            case FreeConstSize:
                //* Do nothing
        }

        var arrow:ArrowCanvas = new ArrowCanvas(dimensions, params, fromPos, toPos, thicknessMultiplier);
        arrowThicknessMultipliers.set(arrowHash, thicknessMultiplier);
        drawnArrows.set(arrowHash, arrow);
        arrowLayer.addComponent(arrow);
    }

    public function removeAllArrows(?color:Null<Color>) 
    {
        for (hash => arrow in drawnArrows.keyValueIterator())
            if (color == null || arrow.params.color.toInt() == color.toInt())
            {
                arrowLayer.removeComponent(arrow);
                arrowThicknessMultipliers.remove(hash);
                drawnArrows.remove(hash);
            }

        for (key in diminishmentOrder.keys())
            diminishmentOrder[key] = 0;
    }

    public function showHexLayer(hexCoords:HexCoords, layer:HexagonLayer) 
    {
        switch hexMode.get(layer) 
        {
            case null | Disabled:
                return;
            case EnsureSingle:
                hideLayerForEveryHex(layer);
            case Free:
                //* Do nothing
        }

        getHex(hexCoords).showLayer(layer);
    }

    public function hideHexLayer(hexCoords:HexCoords, layer:HexagonLayer) 
    {
        getHex(hexCoords).hideLayer(layer);
    }

    public function toggleHexLayer(hexCoords:HexCoords, layer:HexagonLayer) 
    {
        switch hexMode.get(layer) 
        {
            case null | Disabled:
                return;
            case EnsureSingle:
                if (!getHex(hexCoords).layerVisible(layer))
                    hideLayerForEveryHex(layer);
            case Free:
                //* Do nothing
        }

        getHex(hexCoords).toggleLayer(layer);
    }

    public function hideLayerForEveryHex(layer:HexagonLayer) 
    {
        for (hexagon in hexagons)
            hexagon.hideLayer(layer);
    }

    public function addMarker(hexCoords:HexCoords) 
    {
        switch shownSituation.get(hexCoords) 
        {
            case Empty:
                getHex(hexCoords).addDot();
            case Occupied(piece):
                getHex(hexCoords).addCircle();
        }
    }

    public function removeMarker(hexCoords:HexCoords) 
    {
        getHex(hexCoords).removeMarkers();
    }

    public function removeAllMarkers() 
    {
        for (hexagon in hexagons)
            hexagon.removeMarkers();
    }

    public function getAnyDrawnArrow(?color:Color):Null<ArrowParams>
    {
        for (arrow in drawnArrows)
            if (color == null || arrow.params.color.toInt() == color.toInt())
                return arrow.params;

        return null;
    }

    private function updateAllArrows()
    {
        for (hash => arrow in drawnArrows.keyValueIterator())
        {
            var fromPos:Point = hexCoords(arrow.params.from);
            var toPos:Point = hexCoords(arrow.params.to);
            arrow.redraw(dimensions, fromPos, toPos, arrowThicknessMultipliers.get(hash));
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

    public function new(initialSit:Situation, arrowMode:Map<Color, ArrowSelectionMode>, hexMode:Map<HexagonLayer, HexSelectionMode>, orientation:PieceColor = White, ?marks:Marking, ?initialW:Float, ?initialH:Float) 
    {
        super(initialSit, orientation, marks, initialW, initialH);
        this.arrowMode = arrowMode;
        this.hexMode = hexMode;
        this.diminishmentOrder = [for (color in arrowMode.keys()) color => 0];

        arrowLayer = new Absolute();
        addComponent(arrowLayer);
    }
}