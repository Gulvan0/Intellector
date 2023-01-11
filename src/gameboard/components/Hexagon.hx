package gameboard.components;

import gfx.utils.Colors;
import gameboard.components.graphics.HexagonCircleCanvas;
import gameboard.components.graphics.HexagonDotCanvas;
import gameboard.components.graphics.HexagonCanvas;
import gameboard.util.HexDimensions;
import gameboard.util.HexagonSelectionState;
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
    private var layers:Map<HexagonSelectionState, HexagonCanvas> = [];

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

    public function showLayer(state:HexagonSelectionState)
    {
        layers[state].hidden = false;
        if (state == StrongHover)
            layers[PaleHover].hidden = true;
        else if (state == PaleHover)
            layers[StrongHover].hidden = true;
    }

    public function hideLayer(state:HexagonSelectionState)
    {
        layers[state].hidden = true;
        if (state == StrongHover)
            layers[PaleHover].hidden = true;
        else if (state == PaleHover)
            layers[StrongHover].hidden = true;
    }

    public function toggleLayer(state:HexagonSelectionState)
    {
        layers[state].hidden = !layers[state].hidden;
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
        for (state in HexagonSelectionState.createAll())
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