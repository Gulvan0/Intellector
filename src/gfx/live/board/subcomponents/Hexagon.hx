package gfx.live.board.subcomponents;

import gfx.utils.Colors;
import gfx.live.board.subcomponents.canvas.HexagonCircleCanvas;
import gfx.live.board.subcomponents.canvas.HexagonDotCanvas;
import gfx.live.board.subcomponents.canvas.HexagonCanvas;
import gfx.live.board.util.HexDimensions;
import gfx.live.board.util.HexagonLayer;
import haxe.ui.geom.Point;
import net.shared.board.HexCoords;
import net.shared.converters.Notation;
import haxe.ui.util.Color;
import haxe.ui.containers.Absolute;
import haxe.ui.components.Label;
import haxe.ui.graphics.ComponentGraphics;
import haxe.ui.components.Canvas;

class Hexagon extends Absolute
{
    private var layers:Map<HexagonLayer, HexagonCanvas> = [];

    private var number:Label;
    private var dot:HexagonDotCanvas;
    private var circle:HexagonCircleCanvas;

    private var dimensions:HexDimensions;
    private var dark:Bool;
    private var displayedRowNumber:Null<String>;

    private var center:Point;

    public function setDisplayedRowNumber(displayedRowNumber:Null<String>)
    {
        this.displayedRowNumber = displayedRowNumber;
        number.text = displayedRowNumber != null? displayedRowNumber : "";
        number.hidden = displayedRowNumber == null;
    }

    public function showLayer(state:HexagonLayer)
    {
        layers[state].hidden = false;
    }

    public function hideLayer(state:HexagonLayer)
    {
        layers[state].hidden = true;
    }

    public function toggleLayer(state:HexagonLayer)
    {
        layers[state].hidden = !layers[state].hidden;
    }

    public function layerVisible(state:HexagonLayer):Bool
    {
        return !layers[state].hidden;
    }

    private function refreshPosition()
    {
        left = center.x - dimensions.width / 2;
        top = center.y - dimensions.height / 2;
    }

    public function resize(dimensions:HexDimensions, ?newCenter:Point)
    {
        removeAllComponents();

        this.dimensions = dimensions;
        drawChildren();

        if (newCenter != null)
            setCenterAt(newCenter);
        else
            refreshPosition();
    }

    public function setCenterAt(position:Point) 
    {
        center = position;
        refreshPosition();
    }

    public function addDot()
    {
        dot.hidden = false;
        circle.hidden = true;  
    }
    
    public function addCircle()
    {
        circle.hidden = false;  
        dot.hidden = true;
    }

    public function removeMarkers() 
    {
        dot.hidden = true;
        circle.hidden = true;    
    }

    private function drawChildren()
    {
        for (state in [Normal, LastMove, Premove, SelectedForMove, HighlightedByPlayer, Hover])
        {
            var stateHexagon:HexagonCanvas = new HexagonCanvas(dimensions, state, dark);

            if (state != Normal)
                stateHexagon.hidden = true;

            addComponent(stateHexagon);
            layers[state] = stateHexagon;
        }

        width = layers[Normal].width;
        height = layers[Normal].height;

        number = new Label();
        number.customStyle = {
            fontSize: 0.35 * dimensions.sideLength,
            color: Colors.hexRowNumber(dark),
            fontBold: true
        }
        number.left = dimensions.sideLength * 0.15;
        number.top = (dimensions.height - number.customStyle.fontSize) / 2;

        setDisplayedRowNumber(displayedRowNumber);

        dot = new HexagonDotCanvas(width, height, dimensions.sideLength);
        dot.hidden = true;

        circle = new HexagonCircleCanvas(width, height, dimensions.sideLength);
        circle.hidden = true;

        addComponent(number);
        addComponent(dot);
        addComponent(circle);
    }

    public function new(dimensions:HexDimensions, dark:Bool, ?displayedRowNumber:String, ?center:Point)
    {
        super();

        this.dark = dark;
        this.dimensions = dimensions;
        this.displayedRowNumber = displayedRowNumber;

        drawChildren();

        if (center != null)
            setCenterAt(center);
    }
}