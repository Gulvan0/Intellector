package gameboard;

import utils.MathUtils;
import utils.Notation;
import gfx.utils.Colors;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.Sprite;

enum HexagonSelectionState
{
    Normal;
    LastMove;
    Premove;
    LMB;
    RMB;
    Hover;
}

class Hexagon extends Sprite
{
    private var sprites:Map<HexagonSelectionState, Sprite> = [];

    private var number:TextField;
    private var dot:Sprite;
    private var round:Sprite;

    public static function sideToHeight(hexSideLength:Float):Float
    {
        return hexSideLength * Math.sqrt(3);
    }

    public static function sideToWidth(hexSideLength:Float):Float
    {
        return hexSideLength * 2;
    }

    public function showLayer(state:HexagonSelectionState)
    {
        sprites[state].visible = true;
    }

    public function hideLayer(state:HexagonSelectionState)
    {
        sprites[state].visible = false;
    }

    public function toggleLayer(state:HexagonSelectionState)
    {
        sprites[state].visible = !sprites[state].visible;
    }

    public function new(hexSideLength:Float, i:Int, j:Int, displayRowNumber:Bool)
    {
        super();

        var dark:Bool = isDark(i, j);

        for (state in HexagonSelectionState.createAll())
        {
            sprites[state] = drawHex(hexSideLength, Colors.hexFill(state, dark));
            addChild(sprites[state]);
        }

        sprites[Normal].visible = true;

        number = new TextField();
        number.text = Notation.getRow(i, j);
        number.setTextFormat(new TextFormat(null, MathUtils.intScaleLike(14, 40, hexSideLength), Colors.hexRowNumber(dark), true));
        number.selectable = false;
        number.x = -hexSideLength * 0.85;
        number.y = -number.textHeight * 0.75;

        if (displayRowNumber)
            number.visible = false;

        dot = new Sprite();
        dot.graphics.beginFill(0x333333);
        dot.graphics.drawCircle(0, 0, MathUtils.scaleLike(8, 40, hexSideLength));
        dot.graphics.endFill();
        dot.visible = false;

        round = new Sprite();
        round.graphics.lineStyle(4, 0x333333);
        round.graphics.drawCircle(0, 0, 0.8 * hexSideLength);
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

    private function drawHex(hexSideLength:Float, color:Int):Sprite
    {
        var sprite:Sprite = new Sprite();
        var rationalStep = hexSideLength/2;
        var irrationalStep = rationalStep * Math.sqrt(3);

        sprite.graphics.lineStyle(MathUtils.scaleLike(3, 40, hexSideLength), Colors.border);
        sprite.graphics.beginFill(color);
        sprite.graphics.moveTo(-rationalStep, -irrationalStep);
        sprite.graphics.lineTo(rationalStep, -irrationalStep);
        sprite.graphics.lineTo(hexSideLength, 0);
        sprite.graphics.lineTo(rationalStep, irrationalStep);
        sprite.graphics.lineTo(-rationalStep, irrationalStep);
        sprite.graphics.lineTo(-hexSideLength, 0);
        sprite.graphics.lineTo(-rationalStep, -irrationalStep);
        sprite.graphics.endFill();

        sprite.visible = false;

        return sprite;
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