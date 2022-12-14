package gameboard;

import net.shared.converters.Notation;
import openfl.display.Graphics;
import gfx.utils.Colors;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.Sprite;
import net.shared.utils.MathUtils;

enum HexagonSelectionState
{
    Normal;
    LastMove;
    Premove;
    LMB;
    RMB;
    PaleHover;
    StrongHover;
}

class Hexagon extends Sprite
{
    private var sprites:Map<HexagonSelectionState, Sprite> = [];

    private var number:TextField;
    private var dot:Sprite;
    private var round:Sprite;

    private var dark:Bool;

    public static function sideToWidth(hexSideLength:Float):Float
    {
        return hexSideLength * 2;
    }

    public static function sideToHeight(hexSideLength:Float):Float
    {
        return hexSideLength * Math.sqrt(3);
    }

    public static function widthToSide(w:Float):Float
    {
        return w / 2;
    }

    public static function heightToSide(h:Float):Float
    {
        return h / Math.sqrt(3);
    }

    public function setNumberVisibility(isVisible:Bool)
    {
        number.visible = isVisible;
    }

    public function showLayer(state:HexagonSelectionState)
    {
        sprites[state].visible = true;
        if (state == StrongHover)
            sprites[PaleHover].visible = false;
        else if (state == PaleHover)
            sprites[StrongHover].visible = false;
    }

    public function hideLayer(state:HexagonSelectionState)
    {
        sprites[state].visible = false;
        if (state == StrongHover)
            sprites[PaleHover].visible = false;
        else if (state == PaleHover)
            sprites[StrongHover].visible = false;
    }

    public function toggleLayer(state:HexagonSelectionState)
    {
        sprites[state].visible = !sprites[state].visible;
    }

    public function resize(hexSideLength:Float)
    {
        for (state in HexagonSelectionState.createAll())
            drawHex(hexSideLength, Colors.hexFill(state, dark), sprites[state].graphics);
        drawDot(hexSideLength, dot.graphics);
        drawRound(hexSideLength, round.graphics);
        number.setTextFormat(new TextFormat(null, MathUtils.intScaleLike(14, 40, hexSideLength), Colors.hexRowNumber(dark), true));
        number.x = -hexSideLength * 0.85;
        number.y = -number.textHeight * 0.75;
    }

    public function new(hexSideLength:Float, i:Int, j:Int, displayRowNumber:Bool)
    {
        super();
        this.dark = isDark(i, j);

        for (state in HexagonSelectionState.createAll())
        {
            sprites[state] = new Sprite();
            if (state != Normal)
                sprites[state].visible = false;
            addChild(sprites[state]);

            drawHex(hexSideLength, Colors.hexFill(state, dark), sprites[state].graphics);
        }

        number = new TextField();
        number.text = Notation.getRow(i, j);
        number.setTextFormat(new TextFormat(null, MathUtils.intScaleLike(14, 40, hexSideLength), Colors.hexRowNumber(dark), true));
        number.x = -hexSideLength * 0.85;
        number.y = -number.textHeight * 0.75;
        number.selectable = false;
        number.visible = displayRowNumber;

        dot = new Sprite();
        drawDot(hexSideLength, dot.graphics);
        dot.visible = false;

        round = new Sprite();
        drawRound(hexSideLength, round.graphics);
        round.visible = false;

        addChild(number);
        addChild(dot);
        addChild(round);
    }

    public function addDot()
    {
        round.visible = false;  
        dot.visible = true;
    }
    
    public function addRound()
    {
        dot.visible = false;
        round.visible = true;  
    }

    public function removeMarkers() 
    {
        dot.visible = false;
        round.visible = false;    
    }

    private static function drawHex(hexSideLength:Float, color:Int, graphics:Graphics)
    {
        var rationalStep = hexSideLength/2;
        var irrationalStep = rationalStep * Math.sqrt(3);

        graphics.clear();
        graphics.lineStyle(MathUtils.scaleLike(3, 40, hexSideLength), Colors.border);
        graphics.beginFill(color);
        graphics.moveTo(-rationalStep, -irrationalStep);
        graphics.lineTo(rationalStep, -irrationalStep);
        graphics.lineTo(hexSideLength, 0);
        graphics.lineTo(rationalStep, irrationalStep);
        graphics.lineTo(-rationalStep, irrationalStep);
        graphics.lineTo(-hexSideLength, 0);
        graphics.lineTo(-rationalStep, -irrationalStep);
        graphics.endFill();
    }

    private static function drawDot(hexSideLength:Float, graphics:Graphics) 
    {
        graphics.clear();
        graphics.beginFill(0x333333);
        graphics.drawCircle(0, 0, MathUtils.scaleLike(8, 40, hexSideLength));
        graphics.endFill();
    }

    private static function drawRound(hexSideLength:Float, graphics:Graphics) 
    {
        graphics.clear();
        graphics.lineStyle(MathUtils.scaleLike(4, 40, hexSideLength), 0x333333);
        graphics.drawCircle(0, 0, 0.8 * hexSideLength);
    }

    private function isDark(i:Int, j:Int) 
    {
        if (j % 3 == 2)
            return false;
        else if (j % 3 == 0)
            return i % 2 == 0;
        else 
            return i % 2 == 1;
    }
}